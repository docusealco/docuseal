# frozen_string_literal: true

module Abilities
  # Provides authorization conditions for submission access control.
  # Only account users can access submissions (partnership users create templates).
  # Supports partnership inheritance and global template access patterns.
  module SubmissionConditions
    module_function

    def collection(user, request_context: nil)
      return [] if user.account_id.blank?

      submissions_for_user(user, request_context)
    end

    def entity(submission, user:, request_context: nil)
      # Only account users can access submissions
      return false if user.account_id.blank?

      # User can access their own account's submissions
      return true if submission.account_id == user.account_id

      if submission.template_id.present?
        template = submission.template || Template.find_by(id: submission.template_id)
        return false unless template

        return true if user_can_access_template?(user, template, request_context)
      end
      false
    end

    def submissions_for_user(user, request_context = nil)
      accessible_template_ids = accessible_template_ids(request_context)

      Submission.where(
        'submissions.account_id = ? OR submissions.template_id IN (?)',
        user.account_id,
        accessible_template_ids
      )
    end

    def accessible_template_ids(request_context = nil)
      template_ids = []

      # Add templates from partnership context (if provided via API)
      if request_context&.dig(:accessible_partnership_ids).present?
        accessible_partnership_ids = request_context[:accessible_partnership_ids]
        partnership_ids = Partnership.where(external_partnership_id: accessible_partnership_ids).pluck(:id)
        template_ids += Template.where(partnership_id: partnership_ids).pluck(:id)
      end

      # Add templates from global partnership (accessible to everyone)
      if ExportLocation.global_partnership_id.present?
        template_ids += Template.where(partnership_id: ExportLocation.global_partnership_id).pluck(:id)
      end

      template_ids.uniq
    end

    def user_can_access_template?(user, template, request_context = nil)
      # User can access templates from their account
      return true if template.account_id == user.account_id

      # Check partnership context access
      return true if partnership_context_accessible?(template, request_context)

      # Check global partnership access
      return true if global_template_accessible?(template)

      false
    end

    def partnership_context_accessible?(template, request_context)
      return false if request_context&.dig(:accessible_partnership_ids).blank?
      return false if template.partnership_id.blank?

      accessible_partnership_ids = request_context[:accessible_partnership_ids]
      accessible_partnerships = Partnership.where(external_partnership_id: accessible_partnership_ids)

      accessible_partnerships.exists?(id: template.partnership_id)
    end

    def global_template_accessible?(template)
      ExportLocation.global_partnership_id.present? &&
        template.partnership_id == ExportLocation.global_partnership_id
    end
  end
end
