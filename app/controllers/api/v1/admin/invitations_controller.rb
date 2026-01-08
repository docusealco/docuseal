# frozen_string_literal: true

module Api
  module V1
    module Admin
      # InvitationsController
      # Handles admin invitation creation, listing, and revocation
      # Implements rate limiting and security event logging
      class InvitationsController < ApiBaseController
        # Layer 3: Authorization
        authorize_resource class: false

        # Layer 3: Rate limiting for create action
        before_action :check_rate_limit, only: [:create]
        before_action :set_institution
        before_action :verify_super_admin_access, except: [:index]

        # GET /api/v1/admin/invitations
        def index
          # Layer 1: Scoped query
          invitations = CohortAdminInvitation.where(institution: @institution)

          # Layer 4: Filter active vs used
          if params[:show_used] == 'true'
            invitations = invitations.where.not(used_at: nil)
          else
            invitations = invitations.active
          end

          render json: {
            invitations: invitations.map do |inv|
              {
                id: inv.id,
                email: inv.email,
                role: inv.role,
                token_preview: inv.token_preview,
                sent_at: inv.sent_at,
                expires_at: inv.expires_at,
                used_at: inv.used_at,
                created_by: inv.created_by.email
              }
            end
          }
        end

        # POST /api/v1/admin/invitations
        def create
          # Layer 2: Validate role
          unless %w[cohort_admin cohort_super_admin].include?(params[:role])
            return render json: { error: 'Invalid role specified' }, status: :bad_request
          end

          # Layer 3: Use InvitationService for business logic
          begin
            invitation = InvitationService.create_invitation(
              @institution,
              params[:email],
              params[:role],
              current_user
            )

            render json: {
              invitation: {
                id: invitation.id,
                email: invitation.email,
                role: invitation.role,
                token_preview: invitation.token_preview,
                expires_at: invitation.expires_at
              },
              message: 'Invitation created and email sent'
            }, status: :created

          rescue RateLimit::LimitApproached => e
            render json: { error: e.message }, status: :too_many_requests
          rescue CanCan::AccessDenied => e
            render json: { error: e.message }, status: :forbidden
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/invitations/:id
        def destroy
          invitation = CohortAdminInvitation.find_by(id: params[:id], institution: @institution)

          unless invitation
            return render json: { error: 'Invitation not found' }, status: :not_found
          end

          # Use service for revocation
          if InvitationService.revoke_invitation(invitation, current_user)
            render json: { message: 'Invitation revoked successfully' }
          else
            render json: { error: 'Failed to revoke invitation' }, status: :unprocessable_entity
          end
        end

        private

        def set_institution
          @institution = Institution.for_user(current_user).find_by(id: params[:institution_id])

          unless @institution
            log_security_event(:unauthorized_institution_access, {
              attempted_institution_id: params[:institution_id],
              action: 'manage_invitations'
            })
            render json: { error: 'Institution not found or access denied' }, status: :not_found
          end
        end

        def verify_super_admin_access
          unless current_user.cohort_super_admin? && current_user.managed_institutions.exists?(@institution.id)
            log_security_event(:insufficient_privileges, {
              action: 'manage_invitations',
              institution_id: params[:institution_id],
              required_role: 'cohort_super_admin'
            })
            render json: { error: 'Super admin access required' }, status: :forbidden
          end
        end

        def check_rate_limit
          return unless params[:email].present?

          if CohortAdminInvitation.rate_limit_check(params[:email], @institution)
            log_security_event(:rate_limit_exceeded, {
              email: params[:email],
              institution_id: @institution.id,
              limit: InvitationService::MAX_INVITATIONS_PER_EMAIL
            })
            render json: {
              error: "Maximum #{InvitationService::MAX_INVITATIONS_PER_EMAIL} pending invitations per email"
            }, status: :too_many_requests
          end
        end
      end
    end
  end
end