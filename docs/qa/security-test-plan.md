# FloDoc Security Test Plan (Phase 4)

## Overview
This document outlines the comprehensive security testing requirements for the FloDoc Institution Management system, following Winston's IV4 integration verification.

## Test Categories

### 1. Model Layer Security Tests

#### 1.1 Data Isolation Tests
```ruby
# spec/models/institution_spec.rb
describe 'Data Isolation' do
  it 'Institution.for_user returns only accessible institutions' do
    user1 = create(:user)
    user2 = create(:user)
    inst1 = create(:institution, account: user1.account)
    inst2 = create(:institution, account: user2.account)

    expect(Institution.for_user(user1)).to include(inst1)
    expect(Institution.for_user(user1)).not_to include(inst2)
  end

  it 'User.can_access_institution? works correctly' do
    user = create(:user)
    inst = create(:institution, account: user.account)

    # Create access
    create(:account_access, user: user, institution: inst)

    expect(user.can_access_institution?(inst)).to be true
  end
end
```

#### 1.2 Token Security Tests
```ruby
# spec/models/cohort_admin_invitation_spec.rb
describe 'Token Security' do
  it 'generates 512-bit secure tokens' do
    invitation = build(:cohort_admin_invitation)
    token = invitation.generate_token

    expect(token.length).to be >= 64
    expect(invitation.hashed_token).not_to eq(token)
    expect(invitation.token_preview).to match(/\A.{8}\.\.\.\z/)
  end

  it 'validates token with Redis single-use enforcement' do
    invitation = create(:cohort_admin_invitation)
    token = invitation.generate_token
    invitation.save!

    # First validation should succeed
    expect(invitation.valid_token?(token)).to be true

    # Second validation should fail
    expect(invitation.valid_token?(token)).to be false
  end

  it 'rejects expired tokens' do
    invitation = create(:cohort_admin_invitation, expires_at: 1.hour.ago)
    token = invitation.generate_token

    expect(invitation.valid_token?(token)).to be false
  end

  it 'rejects wrong email' do
    invitation = create(:cohort_admin_invitation, email: 'correct@example.com')
    token = invitation.generate_token

    # Simulate wrong email by creating new user with different email
    wrong_user = create(:user, email: 'wrong@example.com')

    expect(invitation.valid_token?(token)).to be true
    # But acceptance should fail
    result = InvitationService.accept_invitation(token, wrong_user)
    expect(result).to be_nil
  end
end
```

#### 1.3 Rate Limiting Tests
```ruby
# spec/services/invitation_service_spec.rb
describe 'Rate Limiting' do
  it 'prevents more than 5 invitations per email' do
    institution = create(:institution)
    user = create(:user)
    email = 'test@example.com'

    # Create 5 valid invitations
    5.times do
      create(:cohort_admin_invitation,
             institution: institution,
             email: email,
             used_at: nil,
             expires_at: 24.hours.from_now)
    end

    expect {
      InvitationService.create_invitation(institution, email, 'cohort_admin', user)
    }.to raise_error(RateLimit::LimitApproached)
  end

  it 'allows new invitations after expiration' do
    institution = create(:institution)
    user = create(:user)
    email = 'test@example.com'

    # Create 5 expired invitations
    5.times do
      create(:cohort_admin_invitation,
             institution: institution,
             email: email,
             used_at: nil,
             expires_at: 1.hour.ago)
    end

    expect {
      InvitationService.create_invitation(institution, email, 'cohort_admin', user)
    }.not_to raise_error
  end
end
```

### 2. Request/Controller Security Tests

#### 2.1 Cross-Institution Access Tests
```ruby
# spec/requests/api/v1/institutions_spec.rb
describe 'Cross-Institution Access Prevention' do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:inst1) { create(:institution, account: user1.account) }
  let(:inst2) { create(:institution, account: user2.account) }

  it 'prevents access to other institutions' do
    sign_in user1

    # Try to access user2's institution
    get "/api/v1/institutions/#{inst2.id}"

    expect(response).to have_http_status(:forbidden)
    expect(SecurityEvent.where(event_type: 'unauthorized_institution_access').count).to eq(1)
  end

  it 'prevents updates to other institutions' do
    sign_in user1

    patch "/api/v1/institutions/#{inst2.id}", params: { institution: { name: 'Hacked' } }

    expect(response).to have_http_status(:forbidden)
    expect(inst2.reload.name).not_to eq('Hacked')
  end
end
```

#### 2.2 Role-Based Access Tests
```ruby
# spec/requests/api/v1/admin/invitations_spec.rb
describe 'Role-Based Authorization' do
  let(:institution) { create(:institution) }
  let(:super_admin) { create(:user) }
  let(:admin) { create(:user) }

  before do
    create(:account_access, user: super_admin, institution: institution, role: 'cohort_super_admin')
    create(:account_access, user: admin, institution: institution, role: 'cohort_admin')
  end

  it 'allows super admin to create invitations' do
    sign_in super_admin

    post '/api/v1/admin/invitations', params: {
      institution_id: institution.id,
      email: 'newadmin@example.com',
      role: 'cohort_admin'
    }

    expect(response).to have_http_status(:created)
  end

  it 'prevents regular admin from creating invitations' do
    sign_in admin

    post '/api/v1/admin/invitations', params: {
      institution_id: institution.id,
      email: 'newadmin@example.com',
      role: 'cohort_admin'
    }

    expect(response).to have_http_status(:forbidden)
  end
end
```

### 3. Token Security Scenarios

#### 3.1 Concurrent Token Validation
```ruby
# spec/requests/api/v1/admin/invitation_acceptance_spec.rb
describe 'Concurrent Token Validation' do
  it 'handles race conditions correctly' do
    invitation = create(:cohort_admin_invitation)
    token = invitation.generate_token
    invitation.save!

    user = create(:user, email: invitation.email)

    # Simulate 50 concurrent requests
    results = 50.times.map do
      Thread.new do
        InvitationService.accept_invitation(token, user)
      end
    end

    # Only one should succeed
    successful = results.map(&:value).compact
    expect(successful.length).to eq(1)

    # Verify token is marked as used
    expect(invitation.reload.used_at).not_to be_nil
  end
end
```

#### 3.2 Token Reuse Prevention
```ruby
it 'prevents token reuse across different users' do
  invitation = create(:cohort_admin_invitation)
  token = invitation.generate_token
  invitation.save!

  user1 = create(:user, email: invitation.email)
  user2 = create(:user, email: invitation.email)

  # First user accepts
  result1 = InvitationService.accept_invitation(token, user1)
  expect(result1).not_to be_nil

  # Second user tries to use same token
  result2 = InvitationService.accept_invitation(token, user2)
  expect(result2).to be_nil
end
```

### 4. Security Event Logging Tests

#### 4.1 Event Capture Tests
```ruby
# spec/models/security_event_spec.rb
describe 'Security Event Logging' do
  it 'logs all 6 event types' do
    user = create(:user)

    events = [
      :unauthorized_institution_access,
      :insufficient_privileges,
      :token_validation_failure,
      :rate_limit_exceeded,
      :invitation_accepted,
      :super_admin_demoted
    ]

    events.each do |event_type|
      SecurityEvent.log(event_type, user, { test: true })
    end

    expect(SecurityEvent.count).to eq(6)
  end

  it 'captures IP address and details' do
    event = SecurityEvent.log(:unauthorized_institution_access, nil, {
      ip_address: '192.168.1.100',
      institution_id: 123,
      attempted_action: 'show'
    })

    expect(event.ip_address).to eq('192.168.1.100')
    expect(event.details['institution_id']).to eq(123)
    expect(event.details['attempted_action']).to eq('show')
  end
end
```

#### 4.2 Alert Threshold Tests
```ruby
describe 'Alert Thresholds' do
  it 'detects unauthorized access threshold' do
    user = create(:user)

    # Create 5 unauthorized access attempts
    5.times do
      SecurityEvent.log(:unauthorized_institution_access, user, {
        institution_id: 999
      })
    end

    expect(SecurityEvent.alert_threshold_exceeded?(
      'unauthorized_institution_access',
      threshold: 5,
      time_window: 1.hour
    )).to be true
  end

  it 'detects token failure threshold' do
    user = create(:user)

    # Create 20 token failures
    20.times do
      SecurityEvent.log(:token_validation_failure, user, {
        reason: 'invalid_token'
      })
    end

    expect(SecurityEvent.alert_threshold_exceeded?(
      'token_validation_failure',
      threshold: 20,
      time_window: 1.hour
    )).to be true
  end
end
```

### 5. Performance Tests

#### 5.1 Query Performance
```ruby
# spec/performance/institution_query_spec.rb
describe 'Institution Query Performance' do
  it 'performs scoped queries efficiently' do
    # Setup: 1000 institutions, 100 users
    account = create(:account)
    1000.times { create(:institution, account: account) }
    users = create_list(:user, 100, account: account)

    # Benchmark
    expect {
      Institution.for_user(users.first).limit(10).to_a
    }.to perform_under(50).ms
  end

  it 'handles concurrent user loads' do
    # 100 concurrent users accessing different institutions
    users = create_list(:user, 100)
    institutions = create_list(:institution, 100)

    threads = users.zip(institutions).map do |user, institution|
      Thread.new do
        create(:account_access, user: user, institution: institution)
        institution.accessible_by?(user)
      end
    end

    threads.each(&:join)
    expect(AccountAccess.count).to eq(100)
  end
end
```

#### 5.2 Redis Performance
```ruby
describe 'Redis Token Enforcement' do
  it 'handles high concurrent token validation' do
    invitation = create(:cohort_admin_invitation)
    token = invitation.generate_token
    invitation.save!

    # 50 concurrent validation attempts
    results = 50.times.map do
      Thread.new do
        invitation.valid_token?(token)
      end
    end

    # Only first should succeed
    valid_count = results.map(&:value).count(true)
    expect(valid_count).to eq(1)
  end
end
```

### 6. Integration Tests

#### 6.1 Complete Invitation Flow
```ruby
# spec/system/invitation_flow_spec.rb
describe 'Complete Invitation Flow' do
  it 'handles full invitation acceptance workflow' do
    # 1. Super admin creates invitation
    super_admin = create(:user)
    institution = create(:institution)
    create(:account_access, user: super_admin, institution: institution, role: 'cohort_super_admin')

    sign_in super_admin
    post '/api/v1/admin/invitations', params: {
      institution_id: institution.id,
      email: 'newadmin@example.com',
      role: 'cohort_admin'
    }

    invitation = CohortAdminInvitation.last
    token = invitation.generate_token # In real flow, this is in Redis

    # 2. New user accepts invitation
    new_user = create(:user, email: 'newadmin@example.com')

    result = InvitationService.accept_invitation(token, new_user)
    expect(result).not_to be_nil

    # 3. Verify access granted
    expect(new_user.cohort_admin?).to be true
    expect(new_user.institutions).to include(institution)

    # 4. Verify security events logged
    expect(SecurityEvent.where(event_type: 'invitation_created').count).to eq(1)
    expect(SecurityEvent.where(event_type: 'invitation_accepted').count).to eq(1)
  end
end
```

#### 6.2 Migration Rollback Test
```ruby
# spec/migrations/rollback_spec.rb
describe 'Migration Rollback' do
  it 'rolls back without data loss' do
    # Setup data
    institution = create(:institution)
    user = create(:user)
    invitation = create(:cohort_admin_invitation, institution: institution)

    # Run rollback
    `bin/rails db:rollback STEP=6`

    # Verify data integrity
    expect(User.exists?(user.id)).to be true
    expect(Account.exists?(institution.account_id)).to be true

    # Verify original functionality still works
    expect(Template.count).to eq(0) # No templates created yet
  end
end
```

### 7. Penetration Testing Scenarios

#### 7.1 SQL Injection Attempts
```ruby
describe 'SQL Injection Prevention' do
  it 'prevents SQL injection in scoped queries' do
    user = create(:user)

    # Attempt SQL injection
    malicious_id = "1; DROP TABLE users; --"

    expect {
      Institution.for_user(user).find_by(id: malicious_id)
    }.not_to raise_error

    # Verify users table still exists
    expect(User.count).to be >= 1
  end
end
```

#### 7.2 Token Brute Force
```ruby
describe 'Token Brute Force Protection' do
  it 'rate limits token validation attempts' do
    invitation = create(:cohort_admin_invitation)
    wrong_tokens = Array.new(100) { SecureRandom.hex(32) }

    # Simulate brute force
    results = wrong_tokens.map do |token|
      invitation.valid_token?(token)
    end

    # All should fail
    expect(results.all?(false)).to be true

    # Check security events logged
    expect(SecurityEvent.where(event_type: 'token_validation_failure').count).to eq(100)
  end
end
```

## Test Execution Plan

### Prerequisites
1. Install Ruby 3.4.2
2. Run `bundle install`
3. Start Redis: `sudo systemctl start redis-server`
4. Start PostgreSQL: `sudo systemctl start postgresql`
5. Run migrations: `bin/rails db:migrate`

### Test Execution Commands

```bash
# Run all security tests
bundle exec rspec spec/models/security_event_spec.rb
bundle exec rspec spec/models/cohort_admin_invitation_spec.rb
bundle exec rspec spec/services/invitation_service_spec.rb
bundle exec rspec spec/requests/api/v1/admin/security_events_spec.rb

# Run performance tests
bundle exec rspec spec/performance/

# Run integration tests
bundle exec rspec spec/system/

# Run penetration tests
bundle exec rspec spec/requests/api/v1/institutions_spec.rb
bundle exec rspec spec/requests/api/v1/admin/invitation_acceptance_spec.rb

# Run all tests with coverage
bundle exec rspec --format documentation --color
```

### Success Criteria

✅ **All tests must pass with:**
- 80% minimum code coverage
- Zero security event violations in production
- Performance within 10% of baseline
- All 6 security event types logged correctly
- Token system handles 50+ concurrent requests
- Rollback procedure verified

### Test Results Documentation

Create `docs/qa/security-test-results-YYYYMMDD.md` with:
- Test execution summary
- Performance metrics
- Security event counts
- Penetration test findings
- Remediation recommendations

---

**Status:** 📋 **READY FOR EXECUTION** (pending Ruby environment setup)