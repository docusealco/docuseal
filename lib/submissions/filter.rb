# frozen_string_literal: true

module Submissions
  module Filter
    ALLOWED_PARAMS = %w[
      author
      completed_at_from
      completed_at_to
      created_at_from
      created_at_to
    ].freeze

    DATE_PARAMS = %w[
      completed_at_from
      completed_at_to
      created_at_from
      created_at_to
    ].freeze

    module_function

    def call(submissions, current_user, params)
      filters = normalize_filter_params(params, current_user)

      if filters[:author].present?
        user = current_user.account.users.find_by(email: filters[:author])
        submissions = submissions.where(created_by_user_id: user&.id || -1)
      end

      submissions = submissions.where(created_at: filters[:created_at_from]..) if filters[:created_at_from].present?

      if filters[:created_at_to].present?
        submissions = submissions.where(created_at: ..filters[:created_at_to].end_of_day)
      end

      if filters[:completed_at_from].present? || filters[:completed_at_to].present?
        completed_arel = Submitter.arel_table[:completed_at].maximum
        submissions = submissions.completed.joins(:submitters).group(:id)

        if filters[:completed_at_from].present?
          submissions = submissions.having(completed_arel.gteq(filters[:completed_at_from]))
        end

        if filters[:completed_at_to].present?
          submissions = submissions.having(completed_arel.lteq(filters[:completed_at_to].end_of_day))
        end
      end

      submissions
    end

    def normalize_filter_params(params, current_user)
      tz = ActiveSupport::TimeZone[current_user.account.timezone] || Time.zone

      ALLOWED_PARAMS.each_with_object({}) do |key, acc|
        next if params[key].blank?

        value = DATE_PARAMS.include?(key) ? tz.parse(params[key]) : params[key]

        acc[key.to_sym] = value
      end
    end
  end
end
