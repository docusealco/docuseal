# frozen_string_literal: true

module Submissions
  module CreateFromSubmitters
    module_function

    def call(template:, user:, submissions_attrs:, source:, submitters_order:, mark_as_sent: false)
      Array.wrap(submissions_attrs).map do |attrs|
        submission = template.submissions.new(created_by_user: user, source:,
                                              template_submitters: template.submitters, submitters_order:)

        attrs[:submitters].each_with_index do |submitter_attrs, index|
          uuid =
            submitter_attrs[:uuid].presence ||
            template.submitters.find { |e| e['name'] == submitter_attrs[:role] }&.dig('uuid') ||
            template.submitters[index]&.dig('uuid')

          next if uuid.blank?

          is_order_sent = submitters_order == 'random' || index.zero?

          build_submitter(submission:, attrs: submitter_attrs, uuid:, is_order_sent:, mark_as_sent:)
        end

        submission.tap(&:save!)
      end
    end

    def build_submitter(submission:, attrs:, uuid:, is_order_sent:, mark_as_sent:)
      email = Submissions.normalize_email(attrs[:email])

      submission.submitters.new(
        email:,
        phone: attrs[:phone].to_s.gsub(/[^0-9+]/, ''),
        name: attrs[:name],
        completed_at: attrs[:completed] ? Time.current : nil,
        sent_at: mark_as_sent && email.present? && is_order_sent ? Time.current : nil,
        values: attrs[:values] || {},
        uuid:
      )
    end
  end
end
