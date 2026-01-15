# Test Design - Story 1.1: Database Schema Extension

**Document**: Comprehensive Test Design for FloDoc Database Schema
**Story**: 1.1 - Database Schema Extension
**Date**: 2026-01-15
**Status**: Draft
**Test Architect**: QA Agent

---

## 📊 Test Strategy Overview

### Brownfield Context
This is a **brownfield enhancement** to the existing DocuSeal codebase. The primary risk is **regression** - ensuring existing DocuSeal functionality remains intact while adding FloDoc's 3-portal cohort management system.

### Test Pyramid Distribution
```
┌─────────────────────────────────────────────────────────┐
│  E2E/System Tests: 10%                                  │
│  - Full cohort workflow                                 │
│  - Integration with DocuSeal templates/submissions     │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│  Integration Tests: 25%                                 │
│  - Referential integrity                                │
│  - Cross-table queries                                  │
│  - Existing table compatibility                         │
└─────────────────────────────────────────────────────────┘
                         ▲
┌─────────────────────────────────────────────────────────┐
│  Unit Tests: 65%                                        │
│  - Migration tests (table creation, indexes, FKs)      │
│  - Schema validation                                    │
│  - Reversibility                                        │
└─────────────────────────────────────────────────────────┘
```

### Key Test Principles
1. **Zero Regression**: All existing DocuSeal tests must pass
2. **Atomic Operations**: Each migration step testable independently
3. **Foreign Key Validation**: All relationships verified
4. **Performance Baseline**: No degradation to existing queries
5. **Data Integrity**: Constraints and unique indexes enforced

---

## 🧪 Unit Test Scenarios (Migration Tests)

### 1.1 Migration File Creation
**File**: `spec/migrations/20260114000001_create_flo_doc_tables_spec.rb`

#### Test Suite 1: Table Creation
```ruby
RSpec.describe CreateFloDocTables, type: :migration do
  describe '1.1.1: Table existence' do
    it 'creates institutions table' do
      expect { migration.change }.to change { table_exists?(:institutions) }.from(false).to(true)
    end

    it 'creates cohorts table' do
      expect { migration.change }.to change { table_exists?(:cohorts) }.from(false).to(true)
    end

    it 'creates cohort_enrollments table' do
      expect { migration.change }.to change { table_exists?(:cohort_enrollments) }.from(false).to(true)
    end
  end
end
```

#### Test Suite 2: Schema Validation (Institutions)
```ruby
describe '1.1.2: Institutions schema' do
  before { migration.change }

  it 'has all required columns' do
    columns = ActiveRecord::Base.connection.columns(:institutions).map(&:name)
    expect(columns).to include(
      'id', 'name', 'email', 'contact_person', 'phone',
      'settings', 'created_at', 'updated_at', 'deleted_at'
    )
  end

  it 'has correct column types' do
    columns_hash = ActiveRecord::Base.connection.columns(:institutions).each_with_object({}) do |col, hash|
      hash[col.name] = col.type
    end

    expect(columns_hash['name']).to eq(:string)
    expect(columns_hash['email']).to eq(:string)
    expect(columns_hash['settings']).to eq(:jsonb)
    expect(columns_hash['deleted_at']).to eq(:datetime)
  end

  it 'enforces NOT NULL constraints' do
    expect { Institution.create!(name: nil, email: 'test@example.com') }
      .to raise_error(ActiveRecord::NotNullViolation)
    expect { Institution.create!(name: 'Test', email: nil) }
      .to raise_error(ActiveRecord::NotNullViolation)
  end

  it 'enforces unique constraints on name' do
    Institution.create!(name: 'Unique', email: 'test1@example.com')
    expect { Institution.create!(name: 'Unique', email: 'test2@example.com') }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'enforces unique constraints on email' do
    Institution.create!(name: 'Test1', email: 'unique@example.com')
    expect { Institution.create!(name: 'Test2', email: 'unique@example.com') }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'allows JSONB settings to be empty' do
    inst = Institution.create!(name: 'Test', email: 'test@example.com')
    expect(inst.settings).to eq({})
  end

  it 'stores JSONB settings correctly' do
    inst = Institution.create!(
      name: 'Test',
      email: 'test@example.com',
      settings: { logo_url: '/logo.png', color: '#123456' }
    )
    inst.reload
    expect(inst.settings['logo_url']).to eq('/logo.png')
    expect(inst.settings['color']).to eq('#123456')
  end
end
```

#### Test Suite 3: Schema Validation (Cohorts)
```ruby
describe '1.1.3: Cohorts schema' do
  before { migration.change }

  it 'has all required columns' do
    columns = ActiveRecord::Base.connection.columns(:cohorts).map(&:name)
    expect(columns).to include(
      'id', 'institution_id', 'template_id', 'name', 'program_type',
      'sponsor_email', 'required_student_uploads', 'cohort_metadata',
      'status', 'tp_signed_at', 'students_completed_at',
      'sponsor_completed_at', 'finalized_at', 'created_at', 'updated_at', 'deleted_at'
    )
  end

  it 'enforces NOT NULL on required fields' do
    institution = create_institution
    template = create_template

    expect {
      Cohort.create!(
        institution_id: nil,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: nil,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: nil,
        program_type: 'learnership',
        sponsor_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: nil,
        sponsor_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: nil
      )
    }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it 'validates program_type inclusion' do
    institution = create_institution
    template = create_template

    valid_types = %w[learnership internship candidacy]
    valid_types.each do |type|
      cohort = Cohort.new(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: type,
        sponsor_email: 'test@example.com'
      )
      expect(cohort).to be_valid
    end

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'invalid_type',
        sponsor_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'validates status inclusion' do
    institution = create_institution
    template = create_template

    valid_statuses = %w[draft active completed]
    valid_statuses.each do |status|
      cohort = Cohort.new(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com',
        status: status
      )
      expect(cohort).to be_valid
    end

    expect {
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com',
        status: 'invalid_status'
      )
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'defaults status to draft' do
    institution = create_institution
    template = create_template

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Test',
      program_type: 'learnership',
      sponsor_email: 'test@example.com'
    )

    expect(cohort.status).to eq('draft')
  end

  it 'stores JSONB fields correctly' do
    institution = create_institution
    template = create_template

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Test',
      program_type: 'learnership',
      sponsor_email: 'test@example.com',
      required_student_uploads: ['id_copy', 'matric_certificate'],
      cohort_metadata: { start_date: '2026-02-01', duration_months: 12 }
    )
    cohort.reload

    expect(cohort.required_student_uploads).to eq(['id_copy', 'matric_certificate'])
    expect(cohort.cohort_metadata['start_date']).to eq('2026-02-01')
    expect(cohort.cohort_metadata['duration_months']).to eq(12)
  end

  it 'allows datetime fields to be nil initially' do
    institution = create_institution
    template = create_template

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Test',
      program_type: 'learnership',
      sponsor_email: 'test@example.com'
    )

    expect(cohort.tp_signed_at).to be_nil
    expect(cohort.students_completed_at).to be_nil
    expect(cohort.sponsor_completed_at).to be_nil
    expect(cohort.finalized_at).to be_nil
  end

  it 'stores datetime fields correctly' do
    institution = create_institution
    template = create_template
    time = Time.current

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Test',
      program_type: 'learnership',
      sponsor_email: 'test@example.com',
      tp_signed_at: time,
      students_completed_at: time,
      sponsor_completed_at: time,
      finalized_at: time
    )
    cohort.reload

    expect(cohort.tp_signed_at).to be_within(1.second).of(time)
    expect(cohort.students_completed_at).to be_within(1.second).of(time)
    expect(cohort.sponsor_completed_at).to be_within(1.second).of(time)
    expect(cohort.finalized_at).to be_within(1.second).of(time)
  end
end
```

#### Test Suite 4: Schema Validation (CohortEnrollments)
```ruby
describe '1.1.4: CohortEnrollments schema' do
  before { migration.change }

  it 'has all required columns' do
    columns = ActiveRecord::Base.connection.columns(:cohort_enrollments).map(&:name)
    expect(columns).to include(
      'id', 'cohort_id', 'submission_id', 'student_email', 'student_name',
      'student_surname', 'student_id', 'status', 'role', 'uploaded_documents',
      'values', 'completed_at', 'created_at', 'updated_at', 'deleted_at'
    )
  end

  it 'enforces NOT NULL on required fields' do
    cohort = create_cohort
    submission = create_submission

    expect {
      CohortEnrollment.create!(
        cohort_id: nil,
        submission_id: submission.id,
        student_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: nil,
        student_email: 'test@example.com'
      )
    }.to raise_error(ActiveRecord::NotNullViolation)

    expect {
      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: nil
      )
    }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it 'defaults status to waiting' do
    cohort = create_cohort
    submission = create_submission

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'test@example.com'
    )

    expect(enrollment.status).to eq('waiting')
  end

  it 'defaults role to student' do
    cohort = create_cohort
    submission = create_submission

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'test@example.com'
    )

    expect(enrollment.role).to eq('student')
  end

  it 'validates status inclusion' do
    cohort = create_cohort
    submission = create_submission

    valid_statuses = %w[waiting in_progress complete]
    valid_statuses.each do |status|
      enrollment = CohortEnrollment.new(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com',
        status: status
      )
      expect(enrollment).to be_valid
    end

    expect {
      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com',
        status: 'invalid_status'
      )
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'validates role inclusion' do
    cohort = create_cohort
    submission = create_submission

    valid_roles = %w[student sponsor]
    valid_roles.each do |role|
      enrollment = CohortEnrollment.new(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com',
        role: role
      )
      expect(enrollment).to be_valid
    end

    expect {
      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com',
        role: 'invalid_role'
      )
    }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'stores JSONB fields correctly' do
    cohort = create_cohort
    submission = create_submission

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'test@example.com',
      uploaded_documents: { 'id_copy' => true, 'matric' => false },
      values: { full_name: 'John Doe', student_number: 'STU001' }
    )
    enrollment.reload

    expect(enrollment.uploaded_documents['id_copy']).to be true
    expect(enrollment.uploaded_documents['matric']).to be false
    expect(enrollment.values['full_name']).to eq('John Doe')
    expect(enrollment.values['student_number']).to eq('STU001')
  end

  it 'allows completed_at to be nil initially' do
    cohort = create_cohort
    submission = create_submission

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'test@example.com'
    )

    expect(enrollment.completed_at).to be_nil
  end

  it 'stores completed_at correctly' do
    cohort = create_cohort
    submission = create_submission
    time = Time.current

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'test@example.com',
      completed_at: time
    )
    enrollment.reload

    expect(enrollment.completed_at).to be_within(1.second).of(time)
  end
end
```

#### Test Suite 5: Indexes
```ruby
describe '1.1.5: Indexes' do
  before { migration.change }

  describe 'Institutions indexes' do
    it 'creates unique index on name' do
      expect(index_exists?(:institutions, :name, unique: true)).to be true
    end

    it 'creates unique index on email' do
      expect(index_exists?(:institutions, :email, unique: true)).to be true
    end
  end

  describe 'Cohorts indexes' do
    it 'creates composite index on institution_id and status' do
      expect(index_exists?(:cohorts, [:institution_id, :status])).to be true
    end

    it 'creates index on template_id' do
      expect(index_exists?(:cohorts, :template_id)).to be true
    end

    it 'creates index on sponsor_email' do
      expect(index_exists?(:cohorts, :sponsor_email)).to be true
    end
  end

  describe 'CohortEnrollments indexes' do
    it 'creates composite index on cohort_id and status' do
      expect(index_exists?(:cohort_enrollments, [:cohort_id, :status])).to be true
    end

    it 'creates unique composite index on cohort_id and student_email' do
      expect(index_exists?(:cohort_enrollments, [:cohort_id, :student_email], unique: true)).to be true
    end

    it 'creates unique index on submission_id' do
      expect(index_exists?(:cohort_enrollments, [:submission_id], unique: true)).to be true
    end
  end
end
```

#### Test Suite 6: Foreign Keys
```ruby
describe '1.1.6: Foreign keys' do
  before { migration.change }

  describe 'Cohorts foreign keys' do
    it 'references institutions' do
      expect(foreign_key_exists?(:cohorts, :institutions)).to be true
    end

    it 'references templates' do
      expect(foreign_key_exists?(:cohorts, :templates)).to be true
    end

    it 'enforces referential integrity on institutions' do
      institution = create_institution
      template = create_template

      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com'
      )

      # Delete institution should fail or cascade
      expect {
        institution.destroy
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it 'enforces referential integrity on templates' do
      institution = create_institution
      template = create_template

      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'test@example.com'
      )

      # Delete template should fail or cascade
      expect {
        template.destroy
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe 'CohortEnrollments foreign keys' do
    it 'references cohorts' do
      expect(foreign_key_exists?(:cohort_enrollments, :cohorts)).to be true
    end

    it 'references submissions' do
      expect(foreign_key_exists?(:cohort_enrollments, :submissions)).to be true
    end

    it 'enforces referential integrity on cohorts' do
      cohort = create_cohort
      submission = create_submission

      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com'
      )

      expect {
        cohort.destroy
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it 'enforces referential integrity on submissions' do
      cohort = create_cohort
      submission = create_submission

      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'test@example.com'
      )

      expect {
        submission.destroy
      }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end
end
```

#### Test Suite 7: Reversibility
```ruby
describe '1.1.7: Migration reversibility' do
  it 'is reversible' do
    expect { migration.change }.not_to raise_error
    expect { migration.reverse }.not_to raise_error
  end

  it 'drops all tables on rollback' do
    migration.change

    expect(table_exists?(:institutions)).to be true
    expect(table_exists?(:cohorts)).to be true
    expect(table_exists?(:cohort_enrollments)).to be true

    migration.reverse

    expect(table_exists?(:institutions)).to be false
    expect(table_exists?(:cohorts)).to be false
    expect(table_exists?(:cohort_enrollments)).to be false
  end

  it 'drops all indexes on rollback' do
    migration.change
    migration.reverse

    # Verify indexes are removed
    expect(index_exists?(:institutions, :name, unique: true)).to be false
    expect(index_exists?(:cohorts, [:institution_id, :status])).to be false
    expect(index_exists?(:cohort_enrollments, [:submission_id], unique: true)).to be false
  end

  it 'drops all foreign keys on rollback' do
    migration.change
    migration.reverse

    expect(foreign_key_exists?(:cohorts, :institutions)).to be false
    expect(foreign_key_exists?(:cohort_enrollments, :cohorts)).to be false
  end
end
```

#### Test Suite 8: Data Integrity
```ruby
describe '1.1.8: Data integrity constraints' do
  before { migration.change }

  describe 'Unique constraints' do
    it 'prevents duplicate institution names' do
      Institution.create!(name: 'Test', email: 'test1@example.com')
      expect {
        Institution.create!(name: 'Test', email: 'test2@example.com')
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'prevents duplicate institution emails' do
      Institution.create!(name: 'Test1', email: 'test@example.com')
      expect {
        Institution.create!(name: 'Test2', email: 'test@example.com')
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'prevents duplicate student enrollments per cohort' do
      cohort = create_cohort
      submission1 = create_submission
      submission2 = create_submission

      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission1.id,
        student_email: 'student@example.com'
      )

      expect {
        CohortEnrollment.create!(
          cohort_id: cohort.id,
          submission_id: submission2.id,
          student_email: 'student@example.com'
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'prevents duplicate submission references' do
      cohort = create_cohort
      submission = create_submission

      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'student1@example.com'
      )

      cohort2 = create_cohort

      expect {
        CohortEnrollment.create!(
          cohort_id: cohort2.id,
          submission_id: submission.id,
          student_email: 'student2@example.com'
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'Cascading deletes' do
    it 'soft deletes institutions' do
      institution = create_institution
      institution.soft_delete

      expect(institution.deleted_at).not_to be_nil
      expect(Institution.where(deleted_at: nil).count).to eq(0)
      expect(Institution.with_deleted.count).to eq(1)
    end

    it 'soft deletes cohorts' do
      cohort = create_cohort
      cohort.soft_delete

      expect(cohort.deleted_at).not_to be_nil
      expect(Cohort.where(deleted_at: nil).count).to eq(0)
    end

    it 'soft deletes cohort_enrollments' do
      enrollment = create_cohort_enrollment
      enrollment.soft_delete

      expect(enrollment.deleted_at).not_to be_nil
      expect(CohortEnrollment.where(deleted_at: nil).count).to eq(0)
    end
  end
end
```

#### Helper Methods for Tests
```ruby
private

def create_institution
  Institution.create!(
    name: "Test Institution #{SecureRandom.hex(4)}",
    email: "test_#{SecureRandom.hex(4)}@example.com"
  )
end

def create_template
  account = Account.create!(name: 'Test Account')
  Template.create!(
    account_id: account.id,
    author_id: 1,
    name: 'Test Template',
    schema: '[]',
    fields: '[]',
    submitters: '[]'
  )
end

def create_submission
  account = Account.create!(name: 'Test Account')
  template = create_template
  Submission.create!(
    account_id: account.id,
    template_id: template.id,
    slug: "test-#{SecureRandom.hex(4)}",
    values: '{}'
  )
end

def create_cohort
  institution = create_institution
  template = create_template
  Cohort.create!(
    institution_id: institution.id,
    template_id: template.id,
    name: 'Test Cohort',
    program_type: 'learnership',
    sponsor_email: 'sponsor@example.com'
  )
end

def create_cohort_enrollment
  cohort = create_cohort
  submission = create_submission
  CohortEnrollment.create!(
    cohort_id: cohort.id,
    submission_id: submission.id,
    student_email: 'student@example.com'
  )
end
```

---

## 🔗 Integration Test Scenarios

### 2.1 Cross-Table Referential Integrity
**File**: `spec/integration/cohort_workflow_spec.rb`

```ruby
RSpec.describe 'Cohort Workflow Integration', type: :integration do
  describe '2.1.1: Existing DocuSeal tables remain unchanged' do
    it 'templates table still works' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Original Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )

      expect(template.name).to eq('Original Template')
      expect(Template.count).to eq(1)
    end

    it 'submissions table still works' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      submission = Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: 'test-slug',
        values: '{}'
      )

      expect(submission.slug).to eq('test-slug')
      expect(Submission.count).to eq(1)
    end

    it 'submitters table still works' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      submission = Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: 'test-slug',
        values: '{}'
      )
      submitter = Submitter.create!(
        submission_id: submission.id,
        email: 'submitter@example.com',
        name: 'Submitter'
      )

      expect(submitter.email).to eq('submitter@example.com')
      expect(Submitter.count).to eq(1)
    end
  end

  describe '2.1.2: New tables reference existing tables' do
    it 'cohorts reference templates correctly' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )

      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test Cohort',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      expect(cohort.template).to eq(template)
      expect(cohort.template.name).to eq('Test Template')
    end

    it 'cohort_enrollments reference submissions correctly' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      submission = Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: 'test-slug',
        values: '{}'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test Cohort',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'student@example.com'
      )

      expect(enrollment.submission).to eq(submission)
      expect(enrollment.submission.slug).to eq('test-slug')
    end

    it 'maintains bidirectional relationships' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      submission = Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: 'test-slug',
        values: '{}'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test Cohort',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )
      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'student@example.com'
      )

      # Cohort -> Enrollments
      expect(cohort.cohort_enrollments).to include(enrollment)

      # Enrollment -> Cohort
      expect(enrollment.cohort).to eq(cohort)

      # Cohort -> Template
      expect(cohort.template).to eq(template)

      # Enrollment -> Submission
      expect(enrollment.submission).to eq(submission)

      # Template -> Cohorts (reverse association)
      expect(template.cohorts).to include(cohort)

      # Submission -> CohortEnrollments (reverse association)
      expect(submission.cohort_enrollments).to include(enrollment)
    end
  end

  describe '2.1.3: Complex queries across tables' do
    it 'joins new and existing tables correctly' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test Cohort',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      # Create multiple enrollments
      3.times do |i|
        submission = Submission.create!(
          account_id: account.id,
          template_id: template.id,
          slug: "test-slug-#{i}",
          values: '{}'
        )
        CohortEnrollment.create!(
          cohort_id: cohort.id,
          submission_id: submission.id,
          student_email: "student#{i}@example.com",
          status: i.even? ? 'complete' : 'waiting'
        )
      end

      # Query: Get all students for a cohort with their submission details
      result = CohortEnrollment
        .joins(:submission, :cohort)
        .where(cohort_id: cohort.id)
        .select('cohort_enrollments.*, submissions.slug, cohorts.name as cohort_name')
        .to_a

      expect(result.length).to eq(3)
      expect(result.map(&:cohort_name).uniq).to eq(['Test Cohort'])
      expect(result.map { |r| r.slug }).to include('test-slug-0', 'test-slug-1', 'test-slug-2')
    end

    it 'filters by status across tables' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )
      cohort1 = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Cohort 1',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com',
        status: 'active'
      )
      cohort2 = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Cohort 2',
        program_type: 'internship',
        sponsor_email: 'sponsor@example.com',
        status: 'draft'
      )

      expect(Cohort.where(status: 'active').count).to eq(1)
      expect(Cohort.where(status: 'active').first.name).to eq('Cohort 1')
    end

    it 'counts related records correctly' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test Template',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test Cohort',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      # Create 5 enrollments
      5.times do |i|
        submission = Submission.create!(
          account_id: account.id,
          template_id: template.id,
          slug: "test-slug-#{i}",
          values: '{}'
        )
        CohortEnrollment.create!(
          cohort_id: cohort.id,
          submission_id: submission.id,
          student_email: "student#{i}@example.com",
          status: i < 3 ? 'complete' : 'waiting'
        )
      end

      expect(cohort.cohort_enrollments.count).to eq(5)
      expect(cohort.cohort_enrollments.completed.count).to eq(3)
      expect(cohort.cohort_enrollments.where(status: 'waiting').count).to eq(2)
    end
  end

  describe '2.1.4: Performance with existing data' do
    it 'handles large numbers of existing DocuSeal records' do
      # Create 100 existing templates and submissions
      account = Account.create!(name: 'Test')
      templates = 100.times.map do |i|
        Template.create!(
          account_id: account.id,
          author_id: 1,
          name: "Template #{i}",
          schema: '[]',
          fields: '[]',
          submitters: '[]'
        )
      end

      submissions = 100.times.map do |i|
        Submission.create!(
          account_id: account.id,
          template_id: templates[i].id,
          slug: "submission-#{i}",
          values: '{}'
        )
      end

      # Now add FloDoc data
      institution = Institution.create!(
        name: 'Test Institution',
        email: 'test@example.com'
      )

      # Create 10 cohorts referencing existing templates
      cohorts = 10.times.map do |i|
        Cohort.create!(
          institution_id: institution.id,
          template_id: templates[i].id,
          name: "Cohort #{i}",
          program_type: 'learnership',
          sponsor_email: 'sponsor@example.com'
        )
      end

      # Create 50 enrollments referencing existing submissions
      50.times do |i|
        CohortEnrollment.create!(
          cohort_id: cohorts[i % 10].id,
          submission_id: submissions[i].id,
          student_email: "student#{i}@example.com"
        )
      end

      # Verify no degradation
      expect(Template.count).to eq(100)
      expect(Submission.count).to eq(100)
      expect(Cohort.count).to eq(10)
      expect(CohortEnrollment.count).to eq(50)

      # Query performance should be acceptable
      start_time = Time.current
      result = CohortEnrollment
        .joins(:submission, :cohort)
        .where(cohorts: { institution_id: institution.id })
        .limit(10)
        .to_a
      end_time = Time.current

      expect(result.length).to eq(10)
      expect(end_time - start_time).to be < 0.1 # Should be fast
    end
  end
end
```

### 2.2 Integration with Existing DocuSeal Workflow
```ruby
describe '2.2: Integration with DocuSeal workflows' do
  it 'allows cohort to reference a template used in existing submissions' do
    account = Account.create!(name: 'Test')

    # Existing DocuSeal workflow
    template = Template.create!(
      account_id: account.id,
      author_id: 1,
      name: 'Standard Contract',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )

    submission = Submission.create!(
      account_id: account.id,
      template_id: template.id,
      slug: 'existing-contract',
      values: '{}'
    )

    submitter = Submitter.create!(
      submission_id: submission.id,
      email: 'client@example.com',
      name: 'Client'
    )

    # New FloDoc workflow
    institution = Institution.create!(
      name: 'Training Institute',
      email: 'admin@institute.com'
    )

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,  # Same template!
      name: '2026 Learnership',
      program_type: 'learnership',
      sponsor_email: 'sponsor@company.com'
    )

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,  # Same submission!
      student_email: 'client@example.com',
      student_name: 'Client'
    )

    # Verify both workflows coexist
    expect(template.submissions.count).to eq(1)
    expect(template.cohorts.count).to eq(1)
    expect(submission.cohort_enrollments.count).to eq(1)

    # Verify data integrity
    expect(cohort.template).to eq(template)
    expect(enrollment.submission).to eq(submission)
    expect(submitter.submission).to eq(submission)
  end

  it 'does not interfere with existing submission completion' do
    account = Account.create!(name: 'Test')
    template = Template.create!(
      account_id: account.id,
      author_id: 1,
      name: 'Test Template',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )

    # Existing submission workflow
    submission = Submission.create!(
      account_id: account.id,
      template_id: template.id,
      slug: 'test-slug',
      values: '{}'
    )

    submitter = Submitter.create!(
      submission_id: submission.id,
      email: 'user@example.com',
      name: 'User'
    )

    # Complete the submission (existing workflow)
    submitter.update!(completed_at: Time.current)

    # Now add FloDoc data
    institution = Institution.create!(
      name: 'Institution',
      email: 'inst@example.com'
    )

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Test Cohort',
      program_type: 'learnership',
      sponsor_email: 'sponsor@example.com'
    )

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'user@example.com'
    )

    # Verify existing workflow still works
    submission.reload
    expect(submission.submitters.first.completed_at).not_to be_nil

    # Verify FloDoc data is separate
    expect(enrollment.completed_at).to be_nil
  end
end
```

---

## 🖥️ System/End-to-End Test Scenarios

### 3.1 Full Cohort Lifecycle
**File**: `spec/system/cohort_lifecycle_spec.rb`

```ruby
RSpec.describe 'Cohort Lifecycle', type: :system do
  describe '3.1.1: Complete 5-step workflow' do
    it 'executes full cohort creation to completion' do
      # Setup
      account = Account.create!(name: 'Test Institution')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Learnership Contract',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )

      institution = Institution.create!(
        name: 'TechPro Academy',
        email: 'admin@techpro.co.za',
        contact_person: 'Jane Smith',
        phone: '+27 11 123 4567'
      )

      # Step 1: Create cohort (draft)
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: '2026 Q1 Learnership',
        program_type: 'learnership',
        sponsor_email: 'sponsor@company.co.za',
        required_student_uploads: ['id_copy', 'matric_certificate'],
        cohort_metadata: {
          start_date: '2026-02-01',
          duration_months: 12,
          stipend_amount: 3500
        },
        status: 'draft'
      )

      expect(cohort.status).to eq('draft')
      expect(cohort.tp_signed_at).to be_nil

      # Step 2: TP signs (activate)
      cohort.update!(
        status: 'active',
        tp_signed_at: Time.current
      )

      expect(cohort.status).to eq('active')
      expect(cohort.tp_signed_at).not_to be_nil

      # Step 3: Students enroll
      5.times do |i|
        submission = Submission.create!(
          account_id: account.id,
          template_id: template.id,
          slug: "student-#{i}-submission",
          values: '{}'
        )

        CohortEnrollment.create!(
          cohort_id: cohort.id,
          submission_id: submission.id,
          student_email: "student#{i}@example.com",
          student_name: "Student#{i}",
          student_surname: "Lastname#{i}",
          student_id: "STU#{i.to_s.rjust(3, '0')}",
          status: 'waiting'
        )
      end

      expect(cohort.cohort_enrollments.count).to eq(5)

      # Step 4: Students complete
      cohort.cohort_enrollments.each do |enrollment|
        enrollment.update!(
          status: 'complete',
          completed_at: Time.current,
          values: { full_name: "#{enrollment.student_name} #{enrollment.student_surname}" }
        )
      end

      cohort.update!(students_completed_at: Time.current)

      expect(cohort.cohort_enrollments.completed.count).to eq(5)
      expect(cohort.students_completed_at).not_to be_nil

      # Step 5: Sponsor signs
      cohort.update!(
        sponsor_completed_at: Time.current
      )

      # Step 6: TP finalizes
      cohort.update!(
        status: 'completed',
        finalized_at: Time.current
      )

      expect(cohort.status).to eq('completed')
      expect(cohort.finalized_at).not_to be_nil
      expect(cohort.sponsor_completed_at).not_to be_nil
    end
  end

  describe '3.1.2: State transitions' do
    it 'follows correct state flow' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      institution = Institution.create!(
        name: 'Test',
        email: 'test@example.com'
      )

      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com',
        status: 'draft'
      )

      # Draft -> Active
      expect(cohort.status).to eq('draft')
      cohort.update!(status: 'active', tp_signed_at: Time.current)
      expect(cohort.status).to eq('active')

      # Active -> Completed
      cohort.update!(status: 'completed', finalized_at: Time.current)
      expect(cohort.status).to eq('completed')
    end
  end
end
```

### 3.2 Database Performance Verification
```ruby
describe '3.2: Performance tests' do
  it 'migration runs in acceptable time' do
    start_time = Time.current
    migration.change
    end_time = Time.current

    expect(end_time - start_time).to be < 30 # seconds
  end

  it 'queries use indexes' do
    migration.change

    # Create test data
    institution = Institution.create!(name: 'Test', email: 'test@example.com')
    template = Template.create!(
      account_id: 1,
      author_id: 1,
      name: 'Test',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )

    100.times do |i|
      Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: "Cohort #{i}",
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com',
        status: i.even? ? 'active' : 'draft'
      )
    end

    # Verify index usage
    explain = Cohort.where(institution_id: institution.id, status: 'active').explain
    expect(explain).to include('Index Scan') || expect(explain).to include('index')
  end

  it 'no performance degradation on existing tables' do
    # Create many existing records
    account = Account.create!(name: 'Test')
    100.times do |i|
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: "Template #{i}",
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: "submission-#{i}",
        values: '{}'
      )
    end

    # Measure query time before FloDoc tables
    start_time = Time.current
    Template.active.limit(10).to_a
    time_before = Time.current - start_time

    # Add FloDoc tables
    migration.change

    # Measure query time after FloDoc tables
    start_time = Time.current
    Template.active.limit(10).to_a
    time_after = Time.current - start_time

    # Should not degrade significantly (allow 50% increase)
    expect(time_after).to be < (time_before * 1.5)
  end
end
```

---

## ⚡ Non-Functional Test Scenarios

### 4.1 Security Tests
```ruby
describe '4.1: Security requirements' do
  before { migration.change }

  describe '4.1.1: Soft delete implementation' do
    it 'includes deleted_at on all tables' do
      %i[institutions cohorts cohort_enrollments].each do |table|
        columns = ActiveRecord::Base.connection.columns(table).map(&:name)
        expect(columns).to include('deleted_at')
      end
    end

    it 'does not physically delete records' do
      institution = Institution.create!(name: 'Test', email: 'test@example.com')
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: 1,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )
      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: 1,
        student_email: 'student@example.com'
      )

      # Soft delete
      institution.soft_delete
      cohort.soft_delete
      enrollment.soft_delete

      # Verify records still exist
      expect(Institution.with_deleted.count).to eq(1)
      expect(Cohort.with_deleted.count).to eq(1)
      expect(CohortEnrollment.with_deleted.count).to eq(1)

      # But not in active scope
      expect(Institution.where(deleted_at: nil).count).to eq(0)
    end
  end

  describe '4.1.2: Foreign key constraints prevent orphaned records' do
    it 'prevents orphaned cohorts' do
      institution = Institution.create!(name: 'Test', email: 'test@example.com')
      template = Template.create!(
        account_id: 1,
        author_id: 1,
        name: 'Test',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )

      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      # Try to delete institution with cohort
      expect { institution.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)

      # Cohort still exists
      expect(Cohort.exists?(cohort.id)).to be true
    end

    it 'prevents orphaned enrollments' do
      cohort = Cohort.create!(
        institution_id: 1,
        template_id: 1,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: 1,
        student_email: 'student@example.com'
      )

      # Try to delete cohort with enrollments
      expect { cohort.destroy }.to raise_error(ActiveRecord::InvalidForeignKey)

      # Enrollment still exists
      expect(CohortEnrollment.exists?(enrollment.id)).to be true
    end
  end

  describe '4.1.3: Sensitive data handling' do
    it 'stores emails in plain text (unless encryption policy enabled)' do
      # Note: Per PRD, encryption is optional
      institution = Institution.create!(name: 'Test', email: 'sensitive@example.com')
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: 1,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: 1,
        student_email: 'student@example.com'
      )

      # Verify emails are stored
      expect(institution.email).to eq('sensitive@example.com')
      expect(cohort.sponsor_email).to eq('sponsor@example.com')
      expect(enrollment.student_email).to eq('student@example.com')

      # Verify they can be queried
      expect(Institution.find_by(email: 'sensitive@example.com')).to eq(institution)
      expect(Cohort.find_by(sponsor_email: 'sponsor@example.com')).to eq(cohort)
      expect(CohortEnrollment.find_by(student_email: 'student@example.com')).to eq(enrollment)
    end
  end
end
```

### 4.2 Data Integrity Tests
```ruby
describe '4.2: Data integrity' do
  before { migration.change }

  describe '4.2.1: Referential integrity' do
    it 'maintains consistency across all tables' do
      account = Account.create!(name: 'Test')
      template = Template.create!(
        account_id: account.id,
        author_id: 1,
        name: 'Test',
        schema: '[]',
        fields: '[]',
        submitters: '[]'
      )
      submission = Submission.create!(
        account_id: account.id,
        template_id: template.id,
        slug: 'test',
        values: '{}'
      )

      institution = Institution.create!(name: 'Test', email: 'test@example.com')
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: template.id,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )
      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: submission.id,
        student_email: 'student@example.com'
      )

      # Verify all relationships
      expect(cohort.institution).to eq(institution)
      expect(cohort.template).to eq(template)
      expect(enrollment.cohort).to eq(cohort)
      expect(enrollment.submission).to eq(submission)

      # Verify reverse relationships
      expect(institution.cohorts).to include(cohort)
      expect(template.cohorts).to include(cohort)
      expect(cohort.cohort_enrollments).to include(enrollment)
      expect(submission.cohort_enrollments).to include(enrollment)
    end
  end

  describe '4.2.2: Unique constraints' do
    it 'enforces institution uniqueness' do
      Institution.create!(name: 'Unique', email: 'test1@example.com')
      expect {
        Institution.create!(name: 'Unique', email: 'test2@example.com')
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'enforces student per cohort uniqueness' do
      cohort = Cohort.create!(
        institution_id: 1,
        template_id: 1,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: 1,
        student_email: 'student@example.com'
      )

      expect {
        CohortEnrollment.create!(
          cohort_id: cohort.id,
          submission_id: 2,
          student_email: 'student@example.com'
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'enforces submission uniqueness' do
      cohort1 = Cohort.create!(
        institution_id: 1,
        template_id: 1,
        name: 'Test1',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      cohort2 = Cohort.create!(
        institution_id: 1,
        template_id: 1,
        name: 'Test2',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )

      CohortEnrollment.create!(
        cohort_id: cohort1.id,
        submission_id: 1,
        student_email: 'student1@example.com'
      )

      expect {
        CohortEnrollment.create!(
          cohort_id: cohort2.id,
          submission_id: 1,
          student_email: 'student2@example.com'
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '4.2.3: Default values' do
    it 'sets correct defaults' do
      institution = Institution.create!(name: 'Test', email: 'test@example.com')
      cohort = Cohort.create!(
        institution_id: institution.id,
        template_id: 1,
        name: 'Test',
        program_type: 'learnership',
        sponsor_email: 'sponsor@example.com'
      )
      enrollment = CohortEnrollment.create!(
        cohort_id: cohort.id,
        submission_id: 1,
        student_email: 'student@example.com'
      )

      expect(cohort.status).to eq('draft')
      expect(cohort.required_student_uploads).to eq([])
      expect(cohort.cohort_metadata).to eq({})
      expect(enrollment.status).to eq('waiting')
      expect(enrollment.role).to eq('student')
      expect(enrollment.uploaded_documents).to eq({})
      expect(enrollment.values).to eq({})
    end
  end
end
```

### 4.3 Compatibility Tests
```ruby
describe '4.3: Backward compatibility' do
  it 'does not modify existing DocuSeal schema' do
    # Get schema before migration
    migration.change

    # Verify existing tables unchanged
    templates_columns = ActiveRecord::Base.connection.columns(:templates).map(&:name)
    expect(templates_columns).to include('name', 'account_id', 'author_id')
    expect(templates_columns).not_to include('flo_doc_specific')

    submissions_columns = ActiveRecord::Base.connection.columns(:submissions).map(&:name)
    expect(submissions_columns).to include('template_id', 'slug', 'values')
    expect(submissions_columns).not_to include('flo_doc_specific')

    submitters_columns = ActiveRecord::Base.connection.columns(:submitters).map(&:name)
    expect(submitters_columns).to include('submission_id', 'email', 'name')
    expect(submitters_columns).not_to include('flo_doc_specific')
  end

  it 'existing DocuSeal operations still work' do
    account = Account.create!(name: 'Test')

    # Create template (existing operation)
    template = Template.create!(
      account_id: account.id,
      author_id: 1,
      name: 'Old Template',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )
    expect(template.name).to eq('Old Template')

    # Create submission (existing operation)
    submission = Submission.create!(
      account_id: account.id,
      template_id: template.id,
      slug: 'old-slug',
      values: '{}'
    )
    expect(submission.slug).to eq('old-slug')

    # Create submitter (existing operation)
    submitter = Submitter.create!(
      submission_id: submission.id,
      email: 'old@example.com',
      name: 'Old User'
    )
    expect(submitter.email).to eq('old@example.com')

    # Complete submission (existing operation)
    submitter.update!(completed_at: Time.current)
    expect(submitter.completed_at).not_to be_nil

    # Verify all still work after FloDoc tables exist
    migration.change

    template2 = Template.create!(
      account_id: account.id,
      author_id: 1,
      name: 'New Template',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )
    expect(template2.name).to eq('New Template')
  end

  it 'allows mixed usage of old and new workflows' do
    account = Account.create!(name: 'Test')

    # Old workflow: Template -> Submission -> Submitter
    template = Template.create!(
      account_id: account.id,
      author_id: 1,
      name: 'Contract',
      schema: '[]',
      fields: '[]',
      submitters: '[]'
    )

    submission = Submission.create!(
      account_id: account.id,
      template_id: template.id,
      slug: 'contract-1',
      values: '{}'
    )

    submitter = Submitter.create!(
      submission_id: submission.id,
      email: 'client@example.com',
      name: 'Client'
    )

    # New workflow: Institution -> Cohort -> CohortEnrollment
    institution = Institution.create!(
      name: 'Training Co',
      email: 'admin@training.com'
    )

    cohort = Cohort.create!(
      institution_id: institution.id,
      template_id: template.id,
      name: 'Training Program',
      program_type: 'learnership',
      sponsor_email: 'sponsor@company.com'
    )

    enrollment = CohortEnrollment.create!(
      cohort_id: cohort.id,
      submission_id: submission.id,
      student_email: 'client@example.com',
      student_name: 'Client'
    )

    # Both workflows coexist
    expect(Template.count).to eq(1)
    expect(Submission.count).to eq(1)
    expect(Submitter.count).to eq(1)
    expect(Institution.count).to eq(1)
    expect(Cohort.count).to eq(1)
    expect(CohortEnrollment.count).to eq(1)

    # Cross-references work
    expect(template.submissions).to include(submission)
    expect(template.cohorts).to include(cohort)
    expect(submission.cohort_enrollments).to include(enrollment)
  end
end
```

---

## 📋 Test Data Requirements

### 5.1 Factory Definitions
**File**: `spec/factories/flo_doc_factories.rb`

```ruby
# Institution Factory
FactoryBot.define do
  factory :institution do
    sequence(:name) { |n| "Institution #{n}" }
    sequence(:email) { |n| "institution#{n}@example.com" }
    contact_person { 'John Doe' }
    phone { '+27 11 123 4567' }
    settings { {} }

    trait :with_logo do
      settings { { logo_url: '/logo.png', primary_color: '#123456' } }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end

# Cohort Factory
FactoryBot.define do
  factory :cohort do
    association :institution
    association :template

    sequence(:name) { |n| "Cohort #{n}" }
    program_type { 'learnership' }
    sequence(:sponsor_email) { |n| "sponsor#{n}@example.com" }
    required_student_uploads { ['id_copy', 'matric_certificate'] }
    cohort_metadata { { start_date: '2026-02-01', duration_months: 12 } }
    status { 'draft' }

    trait :draft do
      status { 'draft' }
    end

    trait :active do
      status { 'active' }
      tp_signed_at { Time.current }
    end

    trait :completed do
      status { 'completed' }
      tp_signed_at { Time.current }
      students_completed_at { Time.current }
      sponsor_completed_at { Time.current }
      finalized_at { Time.current }
    end

    trait :with_students do
      after(:create) do |cohort|
        create_list(:cohort_enrollment, 3, cohort: cohort)
      end
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end

# CohortEnrollment Factory
FactoryBot.define do
  factory :cohort_enrollment do
    association :cohort
    association :submission

    sequence(:student_email) { |n| "student#{n}@example.com" }
    student_name { 'John' }
    student_surname { 'Doe' }
    sequence(:student_id) { |n| "STU#{n.to_s.rjust(3, '0')}" }
    status { 'waiting' }
    role { 'student' }
    uploaded_documents { {} }
    values { {} }

    trait :waiting do
      status { 'waiting' }
    end

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :completed do
      status { 'complete' }
      completed_at { Time.current }
      values { { full_name: 'John Doe' } }
    end

    trait :sponsor do
      role { 'sponsor' }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
```

### 5.2 Test Data Scenarios

#### Scenario 1: Minimal Data
```ruby
# For basic migration tests
let(:minimal_institution) { create(:institution) }
let(:minimal_cohort) { create(:cohort) }
let(:minimal_enrollment) { create(:cohort_enrollment) }
```

#### Scenario 2: Complete Workflow
```ruby
# For integration tests
let(:complete_workflow) do
  institution = create(:institution)
  template = create(:template)
  cohort = create(:cohort, :active, institution: institution, template: template)

  5.times do |i|
    submission = create(:submission, template: template)
    create(:cohort_enrollment, :completed, cohort: cohort, submission: submission)
  end

  cohort.update!(students_completed_at: Time.current)
  cohort.update!(sponsor_completed_at: Time.current)
  cohort.update!(status: 'completed', finalized_at: Time.current)

  cohort
end
```

#### Scenario 3: Large Dataset
```ruby
# For performance tests
let(:large_dataset) do
  institution = create(:institution)
  template = create(:template)

  100.times do |i|
    cohort = create(:cohort, institution: institution, template: template)
    50.times do
      submission = create(:submission, template: template)
      create(:cohort_enrollment, cohort: cohort, submission: submission)
    end
  end
end
```

#### Scenario 4: Edge Cases
```ruby
# For boundary testing
let(:edge_cases) do
  {
    # Empty JSONB fields
    empty_metadata: create(:cohort, cohort_metadata: {}, required_student_uploads: []),

    # Long strings
    long_name: create(:cohort, name: 'A' * 500),

    # Special characters
    special_chars: create(:cohort, name: "Test's \"Special\" & <Chars>"),

    # Multiple emails
    multiple_enrollments: create_list(:cohort_enrollment, 10, cohort: create(:cohort)),

    # Deleted records
    deleted_institution: create(:institution, :deleted),
    deleted_cohort: create(:cohort, :deleted),
    deleted_enrollment: create(:cohort_enrollment, :deleted)
  }
end
```

### 5.3 Database Cleaner Configuration
```ruby
# spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, type: :migration) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

---

## 🚀 Test Execution Plan

### 6.1 Execution Order
Tests must be run in this specific order to ensure proper dependency resolution:

```bash
# Phase 1: Unit Tests (Migration)
bundle exec rspec spec/migrations/20260114000001_create_flo_doc_tables_spec.rb

# Phase 2: Integration Tests
bundle exec rspec spec/integration/cohort_workflow_spec.rb

# Phase 3: System Tests
bundle exec rspec spec/system/cohort_lifecycle_spec.rb

# Phase 4: Existing DocuSeal Tests (Regression)
bundle exec rspec spec/models/template_spec.rb
bundle exec rspec spec/models/submission_spec.rb
bundle exec rspec spec/models/submitter_spec.rb
bundle exec rspec spec/requests/api/v1/templates_spec.rb
bundle exec rspec spec/requests/api/v1/submissions_spec.rb

# Phase 5: Full Suite
bundle exec rspec
```

### 6.2 Test Execution Commands

#### Individual Test Files
```bash
# Migration tests only
bundle exec rspec spec/migrations/20260114000001_create_flo_doc_tables_spec.rb --format documentation

# Integration tests only
bundle exec rspec spec/integration/cohort_workflow_spec.rb --format documentation

# System tests only
bundle exec rspec spec/system/cohort_lifecycle_spec.rb --format documentation

# All FloDoc tests
bundle exec rspec spec/migrations/ spec/integration/ spec/system/ --format documentation

# All existing DocuSeal tests (regression)
bundle exec rspec spec/models/ spec/controllers/ spec/requests/ --tag ~flo_doc --format documentation
```

#### With Coverage
```bash
# Ruby coverage
bundle exec rspec --format documentation
open coverage/index.html

# JavaScript coverage (if applicable)
yarn test --coverage
```

#### Watch Mode (Development)
```bash
# For continuous testing during development
bundle exec rspec spec/migrations/20260114000001_create_flo_doc_tables_spec.rb --format documentation --fail-fast
```

### 6.3 Test Data Setup
```bash
# Before running tests
bin/rails db:test:prepare

# Or manually
RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:schema:load

# Verify test database
RAILS_ENV=test bundle exec rails db:version
```

### 6.4 CI/CD Integration
```yaml
# .github/workflows/story-1-1-tests.yml
name: Story 1.1 - Database Schema Tests

on:
  push:
    branches: [ story/1.1-database-schema ]
  pull_request:
    branches: [ master ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.2
          bundler-cache: true

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'yarn'

      - name: Install dependencies
        run: |
          bundle install
          yarn install

      - name: Setup test database
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: |
          bundle exec rails db:create
          bundle exec rails db:schema:load

      - name: Run Story 1.1 migration tests
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: bundle exec rspec spec/migrations/20260114000001_create_flo_doc_tables_spec.rb --format documentation

      - name: Run integration tests
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: bundle exec rspec spec/integration/cohort_workflow_spec.rb --format documentation

      - name: Run system tests
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: bundle exec rspec spec/system/cohort_lifecycle_spec.rb --format documentation

      - name: Run regression tests
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: bundle exec rspec spec/models/template_spec.rb spec/models/submission_spec.rb --format documentation

      - name: Upload test results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results
          path: |
            coverage/
            tmp/screenshots/

      - name: Check coverage
        env:
          DATABASE_URL: postgresql://postgres:password@localhost:5432/flo_doc_test
          RAILS_ENV: test
        run: |
          bundle exec rspec --format documentation
          if [ $(cat coverage/coverage.last_run.json | jq '.result.line') -lt 80 ]; then
            echo "Coverage below 80%"
            exit 1
          fi
```

### 6.5 Manual Verification Checklist

#### Before Developer Commits
- [ ] All migration tests pass (100%)
- [ ] All integration tests pass (100%)
- [ ] All system tests pass (100%)
- [ ] All existing DocuSeal tests pass (100%)
- [ ] Coverage ≥ 80% for new code
- [ ] No new RuboCop warnings
- [ ] Migration is reversible
- [ ] Performance tests pass (< 30s migration, < 100ms queries)

#### QA Verification
- [ ] Run full test suite on clean database
- [ ] Run tests with existing DocuSeal data
- [ ] Verify rollback works correctly
- [ ] Check database schema.rb is updated
- [ ] Confirm no regression in existing features

#### Database Verification
```bash
# After migration
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:migrate

# Check schema
cat db/schema.rb | grep -A 50 "create_table \"institutions\""
cat db/schema.rb | grep -A 50 "create_table \"cohorts\""
cat db/schema.rb | grep -A 50 "create_table \"cohort_enrollments\""

# Verify indexes
bin/rails runner "puts ActiveRecord::Base.connection.indexes(:cohorts).map(&:name)"
bin/rails runner "puts ActiveRecord::Base.connection.indexes(:cohort_enrollments).map(&:name)"

# Verify foreign keys
bin/rails runner "puts ActiveRecord::Base.connection.foreign_keys(:cohorts).map(&:to_sql)"
bin/rails runner "puts ActiveRecord::Base.connection.foreign_keys(:cohort_enrollments).map(&:to_sql)"
```

### 6.6 Troubleshooting

#### Common Issues
```bash
# Issue: Migration fails due to existing data
# Solution: Clean test database
RAILS_ENV=test bundle exec rails db:drop db:create db:schema:load

# Issue: Foreign key constraint violations
# Solution: Check test data setup order
# Ensure parent records exist before child records

# Issue: Indexes not being used
# Solution: Run ANALYZE on test database
RAILS_ENV=test bundle exec rails runner "ActiveRecord::Base.connection.execute('ANALYZE')"

# Issue: Tests pass locally but fail in CI
# Solution: Check database version differences
# Ensure CI uses same PostgreSQL version as local
```

#### Debug Commands
```bash
# Check table structure
RAILS_ENV=test bundle exec rails runner "p ActiveRecord::Base.connection.columns(:cohorts).map { |c| [c.name, c.type, c.null] }"

# Check indexes
RAILS_ENV=test bundle exec rails runner "p ActiveRecord::Base.connection.indexes(:cohorts).map(&:name)"

# Check foreign keys
RAILS_ENV=test bundle exec rails runner "p ActiveRecord::Base.connection.foreign_keys(:cohorts).map { |fk| [fk.from_table, fk.to_table, fk.column] }"

# Test data count
RAILS_ENV=test bundle exec rails runner "p Institution.count; p Cohort.count; p CohortEnrollment.count"

# Query performance
RAILS_ENV=test bundle exec rails runner "puts Cohort.where(status: 'active').explain"
```

---

## 📊 Success Criteria

### 7.1 Functional Success
- ✅ All 3 tables created with correct schema
- ✅ All indexes created and functional
- ✅ All foreign keys enforced
- ✅ Migrations are 100% reversible
- ✅ No modifications to existing DocuSeal tables
- ✅ All acceptance criteria met

### 7.2 Quality Success
- ✅ 100% of migration tests pass
- ✅ 100% of integration tests pass
- ✅ 100% of system tests pass
- ✅ 100% of existing DocuSeal tests pass (zero regression)
- ✅ Code coverage ≥ 80% for new code
- ✅ Migration time < 30 seconds
- ✅ Query performance < 100ms for common operations

### 7.3 Integration Success
- ✅ New tables reference existing tables correctly
- ✅ Existing workflows remain unaffected
- ✅ Mixed usage (old + new) works seamlessly
- ✅ Referential integrity maintained across all tables

### 7.4 Security Success
- ✅ All tables have soft delete (deleted_at)
- ✅ Foreign keys prevent orphaned records
- ✅ Unique constraints enforced
- ✅ NOT NULL constraints on required fields

---

## 📝 Test Results Template

```markdown
## Test Results - Story 1.1: Database Schema Extension

**Date**: [DATE]
**Tester**: [NAME]
**Environment**: [LOCAL/CI]

### Unit Tests (Migration)
| Test Suite | Status | Pass | Fail | Duration |
|------------|--------|------|------|----------|
| Table Creation | ✅ | 3/3 | 0/3 | [TIME] |
| Schema Validation | ✅ | 30/30 | 0/30 | [TIME] |
| Indexes | ✅ | 7/7 | 0/7 | [TIME] |
| Foreign Keys | ✅ | 6/6 | 0/6 | [TIME] |
| Reversibility | ✅ | 4/4 | 0/4 | [TIME] |
| Data Integrity | ✅ | 12/12 | 0/12 | [TIME] |
| **Total** | **✅** | **62/62** | **0/62** | **[TIME]** |

### Integration Tests
| Test Suite | Status | Pass | Fail | Duration |
|------------|--------|------|------|----------|
| Existing Tables Unchanged | ✅ | 3/3 | 0/3 | [TIME] |
| New Table References | ✅ | 4/4 | 0/4 | [TIME] |
| Complex Queries | ✅ | 4/4 | 0/4 | [TIME] |
| Performance | ✅ | 2/2 | 0/2 | [TIME] |
| DocuSeal Integration | ✅ | 2/2 | 0/2 | [TIME] |
| **Total** | **✅** | **15/15** | **0/15** | **[TIME]** |

### System Tests
| Test Suite | Status | Pass | Fail | Duration |
|------------|--------|------|------|----------|
| Full Lifecycle | ✅ | 2/2 | 0/2 | [TIME] |
| State Transitions | ✅ | 1/1 | 0/1 | [TIME] |
| Performance | ✅ | 3/3 | 0/3 | [TIME] |
| **Total** | **✅** | **6/6** | **0/6** | **[TIME]** |

### Regression Tests
| Test Suite | Status | Pass | Fail | Duration |
|------------|--------|------|------|----------|
| Template Model | ✅ | [X]/[Y] | 0/[Y] | [TIME] |
| Submission Model | ✅ | [X]/[Y] | 0/[Y] | [TIME] |
| Submitter Model | ✅ | [X]/[Y] | 0/[Y] | [TIME] |
| Template API | ✅ | [X]/[Y] | 0/[Y] | [TIME] |
| Submission API | ✅ | [X]/[Y] | 0/[Y] | [TIME] |
| **Total** | **✅** | **[X]/[Y]** | **0/[Y]** | **[TIME]** |

### Coverage
- **Line Coverage**: [XX]%
- **Branch Coverage**: [XX]%
- **Function Coverage**: [XX]%

### Performance
- **Migration Time**: [X]s (Target: <30s)
- **Query Time (avg)**: [X]ms (Target: <100ms)
- **No Degradation**: ✅

### Database Verification
- **Tables Created**: ✅ 3/3
- **Indexes Created**: ✅ 7/7
- **Foreign Keys Created**: ✅ 4/4
- **Schema.rb Updated**: ✅
- **Rollback Works**: ✅

### Overall Status
**[PASS/FAIL]**

**Summary**: [Brief summary of results]

**Issues Found**: [List any issues]

**Recommendation**: [Proceed/Block/Needs Fix]
```

---

## 🎯 Conclusion

This test design provides **comprehensive coverage** for Story 1.1: Database Schema Extension, ensuring:

1. **Zero Regression**: Existing DocuSeal functionality remains intact
2. **Complete Coverage**: All acceptance criteria have corresponding tests
3. **Brownfield Safety**: Tests verify integration with existing tables
4. **Performance Baseline**: No degradation to existing queries
5. **Data Integrity**: All constraints and relationships verified
6. **Reversibility**: Migration can be safely rolled back

**Next Steps**:
1. Developer implements Story 1.1 using this test design
2. Run all tests in specified order
3. Verify coverage meets 80% minimum
4. Submit for QA review with test results
5. QA performs `*review` command to validate

---

**Document Status**: ✅ Complete
**Ready for**: Story 1.1 Implementation
**Test Architect Approval**: Pending
