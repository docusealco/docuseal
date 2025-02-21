# frozen_string_literal: true

module Submissions
  module Filter
    ALLOWED_PARAMS = %w[
      author
      status
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

      submissions = filter_by_author(submissions, filters, current_user)
      submissions = filter_by_status(submissions, filters)
      submissions = filter_by_created_at(submissions, filters)

      filter_by_completed_at(submissions, filters)
    end

    def filter_by_author(submissions, filters, current_user)
      return submissions if filters[:author].blank?

      user = current_user.account.users.find_by(email: filters[:author])
      submissions.where(created_by_user_id: user&.id || -1)
    end

    # rubocop:disable Metrics/MethodLength
    def filter_by_status(submissions, filters)
      case filters[:status]
      when 'pending'
        submissions.pending
      when 'completed'
        submissions.completed
      when 'declined'
        submissions.declined
      when 'expired'
        submissions.expired
      when 'sent'
        submissions.joins(:submitters)
                   .where(submitters: { opened_at: nil, completed_at: nil, declined_at: nil })
                   .where.not(submitters: { sent_at: nil })
                   .group(:id)
      when 'opened'
        submissions.joins(:submitters)
                   .where(submitters: { completed_at: nil, declined_at: nil })
                   .where.not(submitters: { opened_at: nil })
                   .group(:id)
      when 'partially_completed'
        submissions.joins(:submitters)
                   .group(:id)
                   .having(Arel::Nodes::NamedFunction.new(
                     'COUNT', [Arel::Nodes::NamedFunction.new('NULLIF',
                                                              [Submitter.arel_table[:completed_at].eq(nil),
                                                               Arel::Nodes.build_quoted(false)])]
                   ).gt(0))
                   .having(Arel::Nodes::NamedFunction.new(
                     'COUNT', [Arel::Nodes::NamedFunction.new('NULLIF',
                                                              [Submitter.arel_table[:completed_at].not_eq(nil),
                                                               Arel::Nodes.build_quoted(false)])]
                   ).gt(0))
      else
        submissions
      end
    end
    # rubocop:enable Metrics/MethodLength

    def filter_by_created_at(submissions, filters)
      submissions = submissions.where(created_at: filters[:created_at_from]..) if filters[:created_at_from].present?

      if filters[:created_at_to].present?
        submissions = submissions.where(created_at: ..filters[:created_at_to].end_of_day)
      end

      submissions
    end

    def filter_by_completed_at(submissions, filters)
      return submissions unless filters[:completed_at_from].present? || filters[:completed_at_to].present?

      completed_arel = Submitter.arel_table[:completed_at].maximum
      submissions = submissions.completed.joins(:submitters).group(:id)

      if filters[:completed_at_from].present?
        submissions = submissions.having(completed_arel.gteq(filters[:completed_at_from]))
      end

      return submissions if filters[:completed_at_to].blank?

      submissions.having(completed_arel.lteq(filters[:completed_at_to].end_of_day))
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
