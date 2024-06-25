# frozen_string_literal: true

module Abilities
  module TemplateConditions
    module_function

    def collection(user, ability: nil)
      template_ids = Template.where(account_id: user.account_id).select(:id)

      shared_ids =
        TemplateSharing.where({ ability:,
                                account_id: [user.account_id, TemplateSharing::ALL_ID] }.compact)
                       .select(:template_id)

      join_query = Template.arel_table
                           .join(Arel::Nodes::TableAlias.new(template_ids.arel.union(shared_ids.arel), 'union_ids'))
                           .on(Template.arel_table[:id].eq(Arel::Table.new(:union_ids)[:id]))

      Template.joins(join_query.join_sources.first)
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
