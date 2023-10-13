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
        submitter_uuid = find_submitter_uuid(submission.template, submitter_attrs, index)

        process_readonly_fields_param(submitter_attrs[:readonly_fields], template_fields, submitter_uuid)

        process_fields_param(submitter_attrs[:fields], template_fields, submitter_uuid)
      end

      if template_fields != submission.template.fields
        submission.template_fields = template_fields
        submission.template_schema = submission.template.schema
      end

      submission
    end

    def process_readonly_fields_param(readonly_fields, template_fields, submitter_uuid)
      return if readonly_fields.blank?

      template_fields.each do |f|
        next if f['submitter_uuid'] != submitter_uuid ||
                (!f['name'].in?(readonly_fields) &&
                 !f['name'].to_s.parameterize.underscore.in?(readonly_fields))

        f['readonly'] = true
      end
    end

    def process_fields_param(fields, template_fields, submitter_uuid)
      return if fields.blank?

      template_fields.each do |f|
        next if f['submitter_uuid'] != submitter_uuid

        field_configs = fields.find do |e|
          e['name'] == f['name'] || e['name'] == f['name'].to_s.parameterize.underscore
        end

        next if field_configs.blank?

        f['readonly'] = field_configs['readonly'] if field_configs['readonly'].present?

        next if field_configs['validation_pattern'].blank?

        f['validation'] = {
          'pattern' => field_configs['validation_pattern'],
          'message' => field_configs['invalid_message']
        }.compact_blank
      end
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
