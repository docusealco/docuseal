# frozen_string_literal: true

module Submissions
  module CreateFromSubmitters
    module_function

    def call(template:, user:, submissions_attrs:, source:, submitters_order:, mark_as_sent: false)
      Array.wrap(submissions_attrs).map do |attrs|
        submission = template.submissions.new(created_by_user: user, source:,
                                              template_submitters: template.submitters, submitters_order:)

        maybe_set_template_fields(submission, attrs[:submitters])

        attrs[:submitters].each_with_index do |submitter_attrs, index|
          uuid = find_submitter_uuid(template, submitter_attrs, index)

          next if uuid.blank?

          is_order_sent = submitters_order == 'random' || index.zero?

          build_submitter(submission:, attrs: submitter_attrs, uuid:, is_order_sent:, mark_as_sent:)
        end

        submission.tap(&:save!)
      end
    end

    def maybe_set_template_fields(submission, submitters_attrs)
      template_fields = submission.template.fields.deep_dup

      submitters_attrs.each_with_index do |submitter_attrs, index|
        next if submitter_attrs[:readonly_fields].blank?

        uuid = find_submitter_uuid(submission.template, submitter_attrs, index)

        template_fields.each do |f|
          next if f['submitter_uuid'] != uuid ||
                  (!f['name'].in?(submitter_attrs[:readonly_fields]) &&
                   !f['name'].parameterize.underscore.in?(submitter_attrs[:readonly_fields]))

          f['readonly'] = true
        end
      end

      if template_fields != submission.template.fields
        submission.template_fields = template_fields
        submission.template_schema = submission.template.schema
      end

      submission
    end

    def find_submitter_uuid(template, attrs, index)
      attrs[:uuid].presence ||
        template.submitters.find { |e| e['name'] == attrs[:role] }&.dig('uuid') ||
        template.submitters[index]&.dig('uuid')
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
