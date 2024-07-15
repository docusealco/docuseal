# frozen_string_literal: true

module Submitters
  module SerializeForWebhook
    SERIALIZE_PARAMS = {
      methods: %i[status application_key],
      only: %i[id submission_id email phone name ua ip sent_at opened_at
               completed_at created_at updated_at external_id metadata]
    }.freeze

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

      submitter.as_json(SERIALIZE_PARAMS)
               .merge('role' => submitter_name,
                      'preferences' => submitter.preferences.except('default_values'),
                      'values' => values,
                      'documents' => documents,
                      'audit_log_url' => submitter.submission.audit_log_url,
                      'submission_url' => r.submissions_preview_url(submitter.submission.slug,
                                                                    **Docuseal.default_url_options),
                      'template' => submitter.template.as_json(only: %i[id name external_id created_at updated_at],
                                                               methods: %i[folder_name]),
                      'submission' => {
                        **submitter.submission.slice(:id, :audit_log_url, :created_at),
                        status: submitter.submission.submitters.all?(&:completed_at?) ? 'completed' : 'pending',
                        url: r.submissions_preview_url(submitter.submission.slug, **Docuseal.default_url_options)
                      })
    end

    def build_values_array(submitter)
      fields = submitter.submission.template_fields.presence || submitter.submission.template.fields
      attachments_index = submitter.attachments.index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      fields.filter_map do |field|
        submitter_field_counters[field['type']] += 1

        next if field['submitter_uuid'] != submitter.uuid
        next if field['type'] == 'heading'

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        next if !submitter.values.key?(field['uuid']) && !submitter.completed_at?

        value = fetch_field_value(field, submitter.values[field['uuid']], attachments_index)

        { field: field_name, value: }
      end
    end

    def build_fields_array(submitter)
      fields = submitter.submission.template_fields.presence || submitter.submission.template.fields
      attachments_index = submitter.attachments.index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      fields.filter_map do |field|
        submitter_field_counters[field['type']] += 1

        next if field['submitter_uuid'] != submitter.uuid
        next if field['type'] == 'heading'

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        next if !submitter.values.key?(field['uuid']) && !submitter.completed_at?

        value = fetch_field_value(field, submitter.values[field['uuid']], attachments_index)

        { name: field_name, uuid: field['uuid'], value: }
      end
    end

    def build_documents_array(submitter)
      submitter.documents.map do |attachment|
        { name: attachment.filename.base, url: rails_storage_proxy_url(attachment) }
      end
    end

    def fetch_field_value(field, value, attachments_index)
      if field['type'].in?(%w[image signature initials stamp payment])
        rails_storage_proxy_url(attachments_index[value])
      elsif field['type'] == 'file'
        Array.wrap(value).compact_blank.filter_map { |e| rails_storage_proxy_url(attachments_index[e]) }
      else
        value
      end
    end

    def rails_storage_proxy_url(attachment)
      return if attachment.blank?

      ActiveStorage::Blob.proxy_url(attachment.blob)
    end

    def r
      Rails.application.routes.url_helpers
    end
  end
end
