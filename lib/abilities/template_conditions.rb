# frozen_string_literal: true

module Abilities
  module TemplateConditions
    module_function

    def collection(user, ability: nil, request_context: nil)
      # Handle partnership context first
      if request_context && request_context[:accessible_partnership_ids].present?
        return partnership_templates(request_context)
      end

      if user.account_id.present?
        templates = Template.where(account_id: user.account_id)

        return templates unless user.account.testing?

        shared_ids =
          TemplateSharing.where({ ability:, account_id: [user.account_id, TemplateSharing::ALL_ID] }.compact)
                         .select(:template_id)

        Template.where(Template.arel_table[:id].in(Arel::Nodes::Union.new(templates.select(:id).arel, shared_ids.arel)))
      else
        # Partnership users and accounts don't have stored relationships
        # Authorization happens at controller level via request context
        Template.none
      end
    end

    def partnership_templates(request_context)
      accessible_partnership_ids = request_context[:accessible_partnership_ids] || []

      partnership_ids = Partnership.where(external_partnership_id: accessible_partnership_ids).pluck(:id)

      Template.where(partnership_id: partnership_ids)
    end

    def entity(template, user:, ability: nil, request_context: nil)
      return true if template.account_id.blank? && template.partnership_id.blank?

      # Check request context first (from API params)
      if request_context && request_context[:accessible_partnership_ids].present?
        return authorize_via_partnership_context(template, request_context)
      end

      # Handle partnership templates - users don't have stored relationships anymore
      # This should not be reached for partnership users since they use API context

      # Handle regular account templates
      return true if template.account_id == user.account_id
      return false unless user.account&.linked_account_account
      return false if template.template_sharings.to_a.blank?

      account_ids = [user.account_id, TemplateSharing::ALL_ID]

      template.template_sharings.to_a.any? do |e|
        e.account_id.in?(account_ids) && (ability.nil? || e.ability == 'manage' || e.ability == ability)
      end
    end

    def authorize_via_partnership_context(template, request_context)
      accessible_partnership_ids = request_context[:accessible_partnership_ids] || []

      # Handle partnership templates - check if user has access to the partnership
      if template.partnership_id.present?
        partnership = Partnership.find_by(id: template.partnership_id)
        return false unless partnership

        return accessible_partnership_ids.include?(partnership.external_partnership_id)
      end

      # Handle account templates - check if user has access via partnership context
      if template.account_id.present?
        return accessible_partnership_ids.any? && request_context[:external_account_id].present?
      end

      false
    end
  end
end
