# frozen_string_literal: true

# InstitutionSecurity concern
# Provides 4-layer security methods for API controllers
module InstitutionSecurity
  extend ActiveSupport::Concern

  included do
    # Layer 3: Before actions for security
    before_action :verify_institution_access, if: :requires_institution_verification?
    before_action :verify_institution_role, if: :requires_role_verification?
  end

  # Layer 3: Verify institution access (4-layer security)
  def verify_institution_access
    return true unless params[:institution_id].present?

    institution = Institution.find_by(id: params[:institution_id])
    unless institution && current_user.can_access_institution?(institution)
      log_security_event(:unauthorized_institution_access, {
        institution_id: params[:institution_id],
        attempted_action: action_name
      })
      render json: { error: 'Access denied to this institution' }, status: :forbidden
      return false
    end

    # Store institution for use in controller actions
    @current_institution = institution
    true
  end

  # Layer 3: Verify specific role requirements
  def verify_institution_role(required_role = nil)
    required_role ||= required_role_for_action

    return true unless required_role

    case required_role
    when :cohort_super_admin
      unless current_user.cohort_super_admin?
        log_security_event(:insufficient_privileges, {
          required_role: 'cohort_super_admin',
          attempted_action: action_name
        })
        render json: { error: 'Super admin access required' }, status: :forbidden
        return false
      end

    when :cohort_admin
      unless current_user.any_cohort_admin?
        log_security_event(:insufficient_privileges, {
          required_role: 'cohort_admin',
          attempted_action: action_name
        })
        render json: { error: 'Admin access required' }, status: :forbidden
        return false
      end
    end

    true
  end

  # Layer 3: Security event logging
  def log_security_event(event_type, details = {})
    SecurityEvent.log(
      event_type,
      current_user,
      details.merge(
        ip_address: request.remote_ip,
        controller: controller_name,
        action: action_name
      )
    )
  end

  # Layer 4: Scoped query helper (used in controllers)
  def scoped_institutions
    Institution.for_user(current_user)
  end

  def scoped_institution(id)
    scoped_institutions.find_by(id: id)
  end

  private

  # Determine required role for action
  def required_role_for_action
    case action_name
    when 'create', 'update', 'destroy'
      :cohort_super_admin
    when 'show', 'index'
      :cohort_admin
    else
      nil
    end
  end

  # Check if this action requires institution verification
  def requires_institution_verification?
    # Skip for actions that don't use institution_id
    return false if %w[index create].include?(action_name) && !params[:institution_id].present?
    true
  end

  # Check if this action requires role verification
  def requires_role_verification?
    # Most actions require some role check
    true
  end

  # Helper method to get current institution
  def current_institution
    @current_institution ||= if params[:institution_id].present?
      scoped_institutions.find_by(id: params[:institution_id])
    end
  end
end