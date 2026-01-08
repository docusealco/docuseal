# frozen_string_literal: true

# CohortMailer
# Handles email delivery for cohort management
# Implements Winston's secure email requirements
class CohortMailer < ApplicationMailer
  # CRITICAL: Never include raw token in logs
  # CRITICAL: Use HTTPS invitation URL
  # CRITICAL: Token only in email, not in URL params

  def admin_invitation(invitation)
    @invitation = invitation
    @institution = invitation.institution
    @role = invitation.role
    @token = generate_acceptance_token(invitation)

    # Security: Verify we have the token before sending
    unless @token.present?
      Rails.logger.error "No token available for invitation #{invitation.id}"
      return
    end

    # Set email metadata
    @subject = "Invitation to manage #{@institution.name} - #{@role.titleize}"

    # Track email delivery
    mail(
      to: invitation.email,
      subject: @subject,
      track: true
    ) do |format|
      format.html { render 'admin_invitation' }
      format.text { render 'admin_invitation' }
    end
  end

  def super_admin_demoted(user, institution)
    @user = user
    @institution = institution

    mail(
      to: user.email,
      subject: "Role change notification - #{institution.name}"
    )
  end

  private

  # Generate secure acceptance token
  # Note: This retrieves the raw token from Redis if available
  # If not available (already used), returns nil
  def generate_acceptance_token(invitation)
    # The raw token is only available during the initial creation
    # After that, we rely on the invitation flow
    # For security, we don't regenerate tokens

    # In a real implementation, we might store the raw token temporarily
    # in Redis with a short TTL for email delivery
    redis = Redis.current
    key = "invitation_token_pending:#{invitation.hashed_token}"

    # Try to get pending token (set during creation)
    raw_token = redis.get(key)

    # If not found, the invitation might be old or token already delivered
    # In this case, we should not send the email
    return nil unless raw_token

    # Set TTL for the token in email (24 hours from now)
    redis.expire(key, 86400)

    raw_token
  end

  # Override to add security headers
  def mail(headers = {}, &block)
    headers[:'X-SECURITY'] = 'Cohort-Invitation'
    headers[:'X-Role'] = @role if @role
    super(headers, &block)
  end
end