# frozen_string_literal: true

module Submitters
  module SerializeForWebhook
    SERIALIZE_PARAMS = {
      methods: %i[status application_key],
      only: %i[id submission_id email phone name ua ip sent_at opened_at
               completed_at declined_at created_at updated_at external_id metadata]
    }.freeze

    module_function

    def call(submitter, expires_at: Accounts.link_expires_at(Account.new(id: submitter.account_id)))
      ActiveRecord::Associations::Preloader.new(
        records: [submitter], associations: [documents_attachments: :blob, attachments_attachments: :blob]
      ).call

      values = build_values_array(submitter, expires_at:)
      documents = build_documents_array(submitter, expires_at:)

      submission = submitter.submission

      submitter_name = (submission.template_submitters ||
                        submission.template.submitters).find { |e| e['uuid'] == submitter.uuid }['name']

      decline_reason =
        submitter.declined_at? ? submitter.submission_events.find_by(event_type: :decline_form).data['reason'] : nil

      submitter.as_json(SERIALIZE_PARAMS)
               .merge('decline_reason' => decline_reason,
                      'role' => submitter_name,
                      'preferences' => submitter.preferences.except('default_values'),
                      'values' => values,
                      'documents' => documents,
                      'audit_log_url' => submitter.submission.audit_log_url(expires_at:),
                      'submission_url' => r.submissions_preview_url(submission.slug, **Docuseal.default_url_options),
                      'template' => submission.template.as_json(
                        only: %i[id name external_id created_at updated_at], methods: %i[folder_name]
                      ),
                      'submission' => {
                        'id' => submission.id,
                        'audit_log_url' => submission.audit_log_url(expires_at:),
                        'combined_document_url' => submission.combined_document_url(expires_at:),
                        'status' => build_submission_status(submission),
                        'url' => r.submissions_preview_url(submission.slug, **Docuseal.default_url_options),
                        'variables' => (submission.variables || {}).as_json,
                        'created_at' => submission.created_at.as_json
                      })
    end

    def build_values_array(submitter, expires_at: nil)
      fields = submitter.submission.template_fields.presence || submitter.submission&.template&.fields || []
      attachments_index = submitter.attachments.index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      fields.filter_map do |field|
        submitter_field_counters[field['type']] += 1

        next if field['submitter_uuid'] != submitter.uuid
        next if field['type'] == 'heading'

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        next if !submitter.values.key?(field['uuid']) && !submitter.completed_at?

        value = fetch_field_value(field, submitter.values[field['uuid']], attachments_index, expires_at:)

        { 'field' => field_name, 'value' => value }
      end
    end

    def build_fields_array(submitter, expires_at: nil)
      fields = submitter.submission.template_fields.presence || submitter.submission&.template&.fields || []
      attachments_index = submitter.attachments.index_by(&:uuid)
      submitter_field_counters = Hash.new { 0 }

      fields.filter_map do |field|
        submitter_field_counters[field['type']] += 1

        next if field['submitter_uuid'] != submitter.uuid
        next if field['type'] == 'heading'

        field_name =
          field['name'].presence || "#{field['type'].titleize} Field #{submitter_field_counters[field['type']]}"

        next if !submitter.values.key?(field['uuid']) && !submitter.completed_at?

        value = fetch_field_value(field, submitter.values[field['uuid']], attachments_index, expires_at:)

        { 'name' => field_name, 'uuid' => field['uuid'], 'value' => value, 'readonly' => field['readonly'] == true }
      end
    end

    def build_submission_status(submission)
      submitters = submission.submitters

      if submitters.all?(&:completed_at?)
        'completed'
      elsif submitters.any?(&:declined_at?)
        'declined'
      else
        submission.expired? ? 'expired' : 'pending'
      end
    end

    def build_documents_array(submitter, expires_at: nil)
      submitter.documents.map do |attachment|
        { 'name' => attachment.filename.base, 'url' => rails_storage_proxy_url(attachment, expires_at:) }
      end
    end

    def fetch_field_value(field, value, attachments_index, expires_at: nil)
      if field['type'].in?(%w[image signature initials stamp payment kba])
        rails_storage_proxy_url(attachments_index[value], expires_at:)
      elsif field['type'] == 'file'
        Array.wrap(value).compact_blank.filter_map { |e| rails_storage_proxy_url(attachments_index[e], expires_at:) }
      else
        value
      end
    end

    def rails_storage_proxy_url(attachment, expires_at: nil)
      return if attachment.blank?

      ActiveStorage::Blob.proxy_url(attachment.blob, expires_at:)
    end

    def r
      Rails.application.routes.url_helpers
    end
  end
end
