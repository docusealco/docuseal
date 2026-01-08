# frozen_string_literal: true

module Api
  module V1
    module Admin
      # InvitationAcceptanceController
      # Handles token validation and invitation acceptance
      # Implements single-use token enforcement with Redis
      class InvitationAcceptanceController < ApiBaseController
        # Skip authentication for token acceptance (user may not be logged in yet)
        skip_before_action :authenticate_user!, only: [:create]

        # POST /api/v1/admin/invitation_acceptance
        def create
          # Layer 1: Extract and validate token
          raw_token = params[:token]
          email = params[:email]

          unless raw_token.present? && email.present?
            return render json: { error: 'Token and email are required' }, status: :bad_request
          end

          # Layer 2: Find user by email (or create if needed)
          user = User.find_by(email: email)

          unless user
            # In a real implementation, you might want to create the user
            # or require them to register first
            return render json: { error: 'User account not found. Please register first.' }, status: :not_found
          end

          # Layer 3: Use InvitationService for secure acceptance
          invitation = InvitationService.accept_invitation(raw_token, user)

          if invitation
            # Layer 4: Return success with institution info
            render json: {
              message: 'Invitation accepted successfully',
              institution: {
                id: invitation.institution.id,
                name: invitation.institution.name
              },
              role: invitation.role,
              next_steps: 'You can now access the institution dashboard'
            }
          else
            # Security event already logged by service
            render json: { error: 'Invalid or expired token' }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/admin/invitation_acceptance/validate
        # Pre-validate token before showing acceptance form
        def validate
          raw_token = params[:token]
          preview = raw_token[0..7] + '...'

          invitation = CohortAdminInvitation.active.find_by(token_preview: preview)

          if invitation
            render json: {
              valid: true,
              institution_name: invitation.institution.name,
              role: invitation.role,
              expires_at: invitation.expires_at
            }
          else
            render json: {
              valid: false,
              error: 'Invitation not found or expired'
            }, status: :not_found
          end
        end
      end
    end
  end
end