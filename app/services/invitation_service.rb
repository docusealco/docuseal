# frozen_string_literal: true

# InvitationService
# Handles business logic for cohort admin invitations
# Implements Winston's security requirements: rate limiting, token validation, atomic operations
class InvitationService
  # Rate limit configuration
  MAX_INVITATIONS_PER_EMAIL = 5
  INVITATION_EXPIRY_HOURS = 24

  # Create invitation with rate limiting
  def self.create_invitation(institution, email, role, created_by)
    # Layer 1: Rate limiting check
    if CohortAdminInvitation.rate_limit_check(email, institution)
      SecurityEvent.log(:rate_limit_exceeded, created_by, {
        email: email,
        institution_id: institution.id,
        reason: "Max #{MAX_INVITATIONS_PER_EMAIL} pending invitations per email"
      })
      raise RateLimit::LimitApproached, "Too many pending invitations for #{email}"
    end

    # Layer 2: Validate role
    unless %w[cohort_admin cohort_super_admin].include?(role)
      raise ArgumentError, "Invalid role: #{role}"
    end

    # Layer 3: Check authorization
    unless created_by.cohort_super_admin? && created_by.managed_institutions.exists?(institution.id)
      SecurityEvent.log(:insufficient_privileges, created_by, {
        action: 'create_invitation',
        institution_id: institution.id,
        required_role: 'cohort_super_admin'
      })
      raise CanCan::AccessDenied, 'Only super admins can create invitations'
    end

    # Layer 4: Create invitation with atomic token generation
    invitation = CohortAdminInvitation.new(
      institution: institution,
      email: email,
      role: role,
      created_by: created_by,
      expires_at: INVITATION_EXPIRY_HOURS.hours.from_now
    )

    # Generate secure token
    invitation.generate_token

    if invitation.save
      # Log successful creation
      SecurityEvent.log(:invitation_created, created_by, {
        institution_id: institution.id,
        email: email,
        role: role,
        token_preview: invitation.token_preview
      })

      # Queue email delivery
      CohortAdminInvitationJob.perform_async(invitation.id)

      invitation
    else
      raise ActiveRecord::RecordInvalid, invitation
    end
  end

  # Accept invitation with Redis single-use enforcement
  def self.accept_invitation(raw_token, accepting_user)
    # Layer 1: Find invitation by token preview
    preview = raw_token[0..7] + '...'
    invitation = CohortAdminInvitation.active.find_by(token_preview: preview)

    unless invitation
      SecurityEvent.log(:token_validation_failure, accepting_user, {
        reason: 'Invitation not found or expired',
        token_preview: preview
      })
      return nil
    end

    # Layer 2: Email verification
    unless invitation.email == accepting_user.email
      SecurityEvent.log(:token_validation_failure, accepting_user, {
        reason: 'Email mismatch',
        expected_email: invitation.email,
        actual_email: accepting_user.email,
        token_preview: preview
      })
      return nil
    end

    # Layer 3: Token validation with Redis single-use enforcement
    unless invitation.valid_token?(raw_token)
      SecurityEvent.log(:token_validation_failure, accepting_user, {
        reason: 'Invalid or used token',
        token_preview: preview,
        institution_id: invitation.institution_id
      })
      return nil
    end

    # Layer 4: Create account access record (atomic transaction)
    begin
      AccountAccess.create!(
        account: invitation.institution.account,
        user: accepting_user,
        institution: invitation.institution,
        role: invitation.role
      )

      # Log successful acceptance
      SecurityEvent.log(:invitation_accepted, accepting_user, {
        institution_id: invitation.institution_id,
        role: invitation.role,
        invitation_id: invitation.id
      })

      invitation
    rescue ActiveRecord::RecordNotUnique
      # User already has access to this institution
      SecurityEvent.log(:invitation_accepted, accepting_user, {
        institution_id: invitation.institution_id,
        note: 'User already has access',
        invitation_id: invitation.id
      })
      invitation
    end
  end

  # Revoke invitation
  def self.revoke_invitation(invitation, revoked_by)
    # Check authorization
    unless revoked_by.cohort_super_admin? && revoked_by.managed_institutions.exists?(invitation.institution_id)
      SecurityEvent.log(:insufficient_privileges, revoked_by, {
        action: 'revoke_invitation',
        invitation_id: invitation.id
      })
      raise CanCan::AccessDenied, 'Only super admins can revoke invitations'
    end

    # Mark as used (revoked)
    invitation.update!(used_at: Time.current)

    SecurityEvent.log(:invitation_revoked, revoked_by, {
      institution_id: invitation.institution_id,
      email: invitation.email,
      invitation_id: invitation.id
    })

    true
  end

  # Cleanup expired invitations (daily job)
  def self.cleanup_expired
    expired = CohortAdminInvitation.expired.where.not(used_at: nil)
    count = expired.count
    expired.destroy_all
    count
  end

  # Get active invitations for institution
  def self.active_invitations(institution, user)
    unless user.cohort_super_admin? && user.managed_institutions.exists?(institution.id)
      raise CanCan::AccessDenied, 'Access denied'
    end

    CohortAdminInvitation.active.where(institution: institution)
  end
end