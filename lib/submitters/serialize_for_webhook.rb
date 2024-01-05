# frozen_string_literal: true

module Submitters
  module SerializeForWebhook
    module_function

    def call(submitter)
      ActiveRecord::Associations::Preloader.new(
        records: [submitter],
        associations: [documents_attachments: :blob, attachments_attachments: :blob]
      ).call

      values = build_values_array(submitter)
      documents = build_documents_array(submitter)

      submitter_name = (submitter.submission.template_submitters ||
                        submitter.submission.template.submitters).find { |e| e['uuid'] == submitter.uuid }['name']

      submitter.as_json(include: [template: { only: %i[id name created_at updated_at] }])
               .except('uuid', 'values', 'slug')
               .merge('values' => values,
                      'documents' => documents,
                      'audit_log_url' => submitter.submission.audit_log_url,
                      'submission_url' => r.submissions_preview_url(submitter.submission.slug,
                                                                    **Docuseal.default_url_options),
                      'role' => submitter_name)
    end

    def build_values_array(submitter)
      fields = submitter.submission.template_fields.presence || submitter.submission.template.fields
      attachments_index = submitter.attachments.index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      fields.filter_map do |field|
        submitter_field_counters[field['type']] += 1

        next if field['submitter_uuid'] != submitter.uuid

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        next if !submitter.values.key?(field['uuid']) && !submitter.completed_at?

        value = fetch_field_value(field, submitter.values[field['uuid']], attachments_index)

        { field: field_name, value: }
      end
    end

    def build_documents_array(submitter)
      submitter.documents.map do |attachment|
        { name: attachment.filename.base, url: rails_storage_proxy_url(attachment) }
      end
    end

    def fetch_field_value(field, value, attachments_index)
      if field['type'].in?(%w[image signature initials stamp])
        rails_storage_proxy_url(attachments_index[value])
      elsif field['type'] == 'file'
        Array.wrap(value).compact_blank.filter_map { |e| rails_storage_proxy_url(attachments_index[e]) }
      else
        value
      end
    end

    def rails_storage_proxy_url(attachment)
      return if attachment.blank?

      r.rails_storage_proxy_url(attachment, **Docuseal.default_url_options)
    end

    def r
      Rails.application.routes.url_helpers
    end
  end
end
