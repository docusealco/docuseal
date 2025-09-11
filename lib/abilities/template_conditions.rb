# frozen_string_literal: true

module Abilities
  module TemplateConditions
    module_function

    def collection(user, ability: nil)
      if user.account_id.present?
        templates = Template.where(account_id: user.account_id)

        return templates unless user.account.testing?

        shared_ids =
          TemplateSharing.where({ ability:, account_id: [user.account_id, TemplateSharing::ALL_ID] }.compact)
                         .select(:template_id)

        Template.where(Template.arel_table[:id].in(Arel::Nodes::Union.new(templates.select(:id).arel, shared_ids.arel)))
      elsif user.account_group_id.present?
        Template.where(account_group_id: user.account_group_id)
      else
        Template.none
      end
    end

    def entity(template, user:, ability: nil)
      return true if template.account_id.blank? && template.account_group_id.blank?

      # Handle account group templates
      return template.account_group_id == user.account_group_id if template.account_group_id.present?

      # Handle regular account templates
      return true if template.account_id == user.account_id
      return false unless user.account&.linked_account_account
      return false if template.template_sharings.to_a.blank?

      account_ids = [user.account_id, TemplateSharing::ALL_ID]

      template.template_sharings.to_a.any? do |e|
        e.account_id.in?(account_ids) && (ability.nil? || e.ability == 'manage' || e.ability == ability)
      end
    end
  end
end
