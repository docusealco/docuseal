# frozen_string_literal: true

# CohortAdminInvitationJob
# Delivers invitation emails asynchronously
# Implements Winston's asynchronous security requirements
class CohortAdminInvitationJob
  include Sidekiq::Job

  sidekiq_options queue: :mailers, retry: 5

  def perform(invitation_id)
    invitation = CohortAdminInvitation.find_by(id: invitation_id)

    # Check if invitation still valid
    unless invitation && invitation.active? && !invitation.used?
      Rails.logger.warn "Invitation #{invitation_id} no longer valid for email delivery"
      return
    end

    # Send email
    begin
      CohortMailer.admin_invitation(invitation).deliver_now

      # Update sent_at timestamp
      invitation.update!(sent_at: Time.current)

      # Log successful delivery
      SecurityEvent.log(:email_sent, invitation.created_by, {
        institution_id: invitation.institution_id,
        email: invitation.email,
        invitation_id: invitation.id
      })

      Rails.logger.info "Invitation email sent to #{invitation.email}"

    rescue StandardError => e
      # Log failure
      SecurityEvent.log(:email_delivery_failure, invitation.created_by, {
        institution_id: invitation.institution_id,
        email: invitation.email,
        invitation_id: invitation.id,
        error: e.message
      })

      Rails.logger.error "Failed to send invitation email: #{e.message}"
      raise # Re-raise to trigger retry
    end
  end

  # Additional safety check
  def self.perform_async_if_valid(invitation_id)
    invitation = CohortAdminInvitation.find_by(id: invitation_id)
    return false unless invitation
    return false unless invitation.active?
    return false if invitation.sent_at.present?

    perform_async(invitation_id)
    true
  end
end