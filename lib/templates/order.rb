# frozen_string_literal: true

module Templates
  module Order
    module_function

    def call(templates, current_user, order)
      case order
      when 'used_at'
        last_submission_created_at = last_submission_created_at(current_user)

        templates.order(
          Arel::Nodes::Case.new
                           .when(last_submission_created_at.gt(Template.arel_table[:updated_at]))
                           .then(last_submission_created_at)
                           .else(Template.arel_table[:updated_at])
                           .desc
        )
      when 'name'
        templates.order(name: :asc)
      else
        templates.order(id: :desc)
      end
    end

    def last_submission_created_at(current_user)
      Arel::Nodes::Grouping.new(
        Submission.where(account_id: current_user.account_id, archived_at: nil)
                  .where(Submission.arel_table[:template_id].eq(Template.arel_table[:id]))
                  .order(id: :desc)
                  .limit(1)
                  .select(:created_at)
                  .arel
      )
    end
  end
end
