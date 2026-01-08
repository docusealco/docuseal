# frozen_string_literal: true

module Api
  module V1
    # InstitutionsController
    # Handles CRUD operations for institutions
    # Implements Winston's 4-layer security architecture
    class InstitutionsController < ApiBaseController
      # Layer 3: Authorization - check CanCanCan abilities
      authorize_resource

      # Layer 3: Security verification
      before_action :verify_institution_access, except: [:index, :create]
      before_action :set_institution, only: [:show, :update, :destroy]

      # GET /api/v1/institutions
      def index
        # Layer 1: Database-level security via scope
        @institutions = Institution.for_user(current_user)

        # Layer 4: Add role information for UI
        @institutions_with_roles = @institutions.map do |inst|
          {
            id: inst.id,
            name: inst.name,
            registration_number: inst.registration_number,
            contact_email: inst.contact_email,
            role: inst.user_role(current_user),
            is_super_admin: inst.super_admin?(current_user),
            created_at: inst.created_at
          }
        end

        render json: { institutions: @institutions_with_roles }
      end

      # GET /api/v1/institutions/:id
      def show
        # Layer 1: Scoped query (already verified by before_action)
        # Layer 2: CanCanCan ability check
        # Layer 3: verify_institution_access already ran

        render json: {
          institution: @institution,
          role: @institution.user_role(current_user),
          is_super_admin: @institution.super_admin?(current_user),
          settings: @institution.settings_with_defaults
        }
      end

      # POST /api/v1/institutions
      def create
        # Layer 3: Authorization check (super admin only)
        unless current_user.cohort_super_admin?
          log_security_event(:insufficient_privileges, {
            action: 'create_institution',
            required_role: 'cohort_super_admin'
          })
          return render json: { error: 'Super admin access required' }, status: :forbidden
        end

        # Layer 4: Strong parameters validation
        @institution = Institution.new(institution_params)
        @institution.account = current_user.account
        @institution.super_admin = current_user

        if @institution.save
          # Create initial account access for super admin
          AccountAccess.create!(
            account: current_user.account,
            user: current_user,
            institution: @institution,
            role: 'cohort_super_admin'
          )

          log_security_event(:institution_created, {
            institution_id: @institution.id,
            name: @institution.name
          })

          render json: {
            institution: @institution,
            message: 'Institution created successfully'
          }, status: :created
        else
          render json: { errors: @institution.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/institutions/:id
      def update
        # Layer 3: Authorization (super admin only for updates)
        unless @institution.super_admin?(current_user)
          log_security_event(:insufficient_privileges, {
            action: 'update_institution',
            institution_id: @institution.id,
            required_role: 'super_admin'
          })
          return render json: { error: 'Only super admins can update institutions' }, status: :forbidden
        end

        if @institution.update(institution_params)
          log_security_event(:institution_updated, {
            institution_id: @institution.id,
            changes: institution_params.keys
          })

          render json: { institution: @institution, message: 'Updated successfully' }
        else
          render json: { errors: @institution.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/institutions/:id
      def destroy
        # Layer 3: Authorization (super admin only)
        unless @institution.super_admin?(current_user)
          log_security_event(:insufficient_privileges, {
            action: 'destroy_institution',
            institution_id: @institution.id,
            required_role: 'super_admin'
          })
          return render json: { error: 'Only super admins can delete institutions' }, status: :forbidden
        end

        # Safety check: Don't delete if has active cohorts
        if @institution.cohorts.exists?
          return render json: {
            error: 'Cannot delete institution with active cohorts. Archive cohorts first.'
          }, status: :unprocessable_entity
        end

        institution_name = @institution.name
        @institution.destroy!

        log_security_event(:institution_deleted, {
          institution_name: institution_name
        })

        render json: { message: "Institution '#{institution_name}' deleted successfully" }
      end

      private

      def set_institution
        # Layer 1: Scoped query for security
        @institution = Institution.for_user(current_user).find_by(id: params[:id])

        unless @institution
          log_security_event(:unauthorized_institution_access, {
            attempted_institution_id: params[:id]
          })
          render json: { error: 'Institution not found or access denied' }, status: :not_found
        end
      end

      def institution_params
        # Layer 4: Strong parameters
        params.require(:institution).permit(
          :name,
          :registration_number,
          :address,
          :contact_email,
          :contact_phone,
          settings: [
            :allow_student_enrollment,
            :require_verification,
            :auto_finalize,
            :email_notifications
          ]
        )
      end
    end
  end
end