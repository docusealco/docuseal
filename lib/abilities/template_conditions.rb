# frozen_string_literal: true

module Abilities
  module TemplateConditions
    module_function

    def collection(user, ability: nil)
      shared_ids =
        Template.joins(:template_sharings)
                .where(template_sharings: { ability:,
                                            account_id: [user.account_id, TemplateSharing::ALL_ID] }.compact)
                .select(:id)

      Template.where(account_id: user.account_id).or(Template.where(id: shared_ids))
    end

    def entity(template, user:, ability: nil)
      return true if template.account_id == user.account_id

      account_ids = [user.account_id, TemplateSharing::ALL_ID]

      template.template_sharings.any? do |e|
        e.account_id.in?(account_ids) && (ability.nil? || e.ability == ability)
      end
    end
  end
end
