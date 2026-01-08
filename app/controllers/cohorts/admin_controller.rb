# frozen_string_literal: true

module Cohorts
  # AdminController
  # Web interface for cohort management
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_cohort_access

    def index
      # Show dashboard with user's institutions
      @institutions = Institution.for_user(current_user)
      @can_create = current_user.cohort_super_admin?
    end

    def show
      # Institution details page
      @institution = Institution.for_user(current_user).find_by(id: params[:id])
      redirect_to cohorts_admin_index_path, alert: 'Institution not found' unless @institution

      @role = @institution.user_role(current_user)
      @is_super_admin = @institution.super_admin?(current_user)
    end

    def new
      # New institution form
      unless current_user.cohort_super_admin?
        redirect_to cohorts_admin_index_path, alert: 'Access denied'
      end

      @institution = Institution.new
    end

    def create
      # Create new institution
      unless current_user.cohort_super_admin?
        redirect_to cohorts_admin_index_path, alert: 'Access denied'
        return
      end

      @institution = Institution.new(institution_params)
      @institution.account = current_user.account
      @institution.super_admin = current_user

      if @institution.save
        # Create initial access
        AccountAccess.create!(
          account: current_user.account,
          user: current_user,
          institution: @institution,
          role: 'cohort_super_admin'
        )

        redirect_to cohorts_admin_path(@institution), notice: 'Institution created successfully'
      else
        render :new
      end
    end

    def edit
      # Edit institution form
      @institution = Institution.for_user(current_user).find_by(id: params[:id])
      redirect_to cohorts_admin_index_path, alert: 'Institution not found' unless @institution

      unless @institution.super_admin?(current_user)
        redirect_to cohorts_admin_path(@institution), alert: 'Only super admins can edit'
      end
    end

    def update
      # Update institution
      @institution = Institution.for_user(current_user).find_by(id: params[:id])
      redirect_to cohorts_admin_index_path, alert: 'Institution not found' unless @institution

      unless @institution.super_admin?(current_user)
        redirect_to cohorts_admin_path(@institution), alert: 'Only super admins can update'
        return
      end

      if @institution.update(institution_params)
        redirect_to cohorts_admin_path(@institution), notice: 'Updated successfully'
      else
        render :edit
      end
    end

    def invite
      # Show invite form
      @institution = Institution.for_user(current_user).find_by(id: params[:institution_id])
      redirect_to cohorts_admin_index_path, alert: 'Institution not found' unless @institution

      unless @institution.super_admin?(current_user)
        redirect_to cohorts_admin_path(@institution), alert: 'Access denied'
      end

      @invitation = CohortAdminInvitation.new
    end

    def send_invitation
      # Process invitation
      @institution = Institution.for_user(current_user).find_by(id: params[:institution_id])
      redirect_to cohorts_admin_index_path, alert: 'Institution not found' unless @institution

      unless @institution.super_admin?(current_user)
        redirect_to cohorts_admin_path(@institution), alert: 'Access denied'
        return
      end

      begin
        InvitationService.create_invitation(
          @institution,
          params[:email],
          params[:role],
          current_user
        )

        redirect_to cohorts_admin_path(@institution), notice: 'Invitation sent'
      rescue RateLimit::LimitApproached => e
        redirect_to invite_cohorts_admin_path(@institution), alert: e.message
      rescue StandardError => e
        redirect_to invite_cohorts_admin_path(@institution), alert: "Error: #{e.message}"
      end
    end

    private

    def verify_cohort_access
      # Ensure user has cohort access
      unless current_user.any_cohort_admin?
        redirect_to root_path, alert: 'You do not have access to cohort management'
      end
    end

    def institution_params
      params.require(:institution).permit(
        :name,
        :registration_number,
        :address,
        :contact_email,
        :contact_phone
      )
    end
  end
end