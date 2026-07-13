# frozen_string_literal: true

module Submissions
  module Filter
    ALLOWED_PARAMS = %w[
      author
      status
      folder
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

    BIGINT_MAX = (2**63) - 1

    module_function

    def call(submissions, current_user, params)
      filters = normalize_filter_params(params, current_user)

      submissions = filter_by_author(submissions, filters, current_user)
      submissions = filter_by_folder(submissions, filters, current_user)
      submissions = filter_by_status(submissions, filters)
      submissions = filter_by_created_at(submissions, filters)

      filter_by_completed_at(submissions, filters)
    end

    def filter_by_author(submissions, filters, current_user)
      return submissions if filters[:author].blank?

      user = current_user.account.users.find_by(email: filters[:author])

      submissions.where(created_by_user_id: user&.id || -1)
    end

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
        submissions.where(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id]))
                                   .where(opened_at: nil, completed_at: nil, declined_at: nil)
                                   .where.not(sent_at: nil)
                                   .limit(1).arel.exists)
      when 'opened'
        submissions.where(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id]))
                                   .where(completed_at: nil, declined_at: nil)
                                   .where.not(opened_at: nil)
                                   .limit(1).arel.exists)
      when 'partially_completed'
        submissions.where(completed_at: nil)
                   .where(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id]))
                                   .where.not(completed_at: nil)
                                   .limit(1).arel.exists)
      else
        submissions
      end
    end

    def filter_by_created_at(submissions, filters)
      if filters[:created_at_from].present?
        submissions = submissions.where(min_created_at_id_arel(filters[:created_at_from]))
      end

      if filters[:created_at_to].present?
        submissions = submissions.where(max_created_at_id_arel(filters[:created_at_to].end_of_day))
      end

      submissions
    end

    def min_created_at_id_arel(time)
      submissions = Submission.arel_table

      first_id = submissions.project(submissions[:id])
                            .where(submissions[:created_at].gteq(time))
                            .order(submissions[:created_at].asc, submissions[:id].asc)
                            .take(1)

      submissions[:id].gteq(Arel::Nodes::NamedFunction.new('COALESCE', [first_id, BIGINT_MAX]))
    end

    def max_created_at_id_arel(time)
      submissions = Submission.arel_table

      last_id = submissions.project(submissions[:id])
                           .where(submissions[:created_at].lteq(time))
                           .order(submissions[:created_at].desc, submissions[:id].desc)
                           .take(1)

      submissions[:id].lteq(Arel::Nodes::NamedFunction.new('COALESCE', [last_id, 0]))
    end

    def filter_by_folder(submissions, filters, current_user)
      return submissions if filters[:folder].blank?

      folders =
        TemplateFolders.filter_by_full_name(current_user.account.template_folders, filters[:folder])

      folders += folders.preload(:subfolders).flat_map(&:subfolders)

      submissions.joins(:template).where(templates: { folder_id: folders.map(&:id) })
    end

    def filter_by_completed_at(submissions, filters)
      return submissions unless filters[:completed_at_from].present? || filters[:completed_at_to].present?

      submissions = submissions.completed

      if filters[:completed_at_from].present?
        submissions = submissions.where(completed_at: filters[:completed_at_from]..)
      end

      return submissions if filters[:completed_at_to].blank?

      submissions.where(completed_at: ..filters[:completed_at_to].end_of_day)
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
