# frozen_string_literal: true

module Templates
  module Order
    module_function

    def call(templates, current_user, order)
      case order
      when 'used_at'
        subquery = Submission.select(:template_id, Submission.arel_table[:created_at].maximum.as('created_at'))
                             .where(account_id: current_user.account_id)
                             .group(:template_id)

        templates = templates.joins(
          Template.arel_table
                  .join(subquery.arel.as('submissions'), Arel::Nodes::OuterJoin)
                  .on(Template.arel_table[:id].eq(Submission.arel_table[:template_id]))
                  .join_sources
        )

        templates.order(
          Arel::Nodes::Case.new
                           .when(Submission.arel_table[:created_at].gt(Template.arel_table[:updated_at]))
                           .then(Submission.arel_table[:created_at])
                           .else(Template.arel_table[:updated_at])
                           .desc
        )
      when 'name'
        templates.order(name: :asc)
      else
        templates.order(id: :desc)
      end
    end
  end
end
