# frozen_string_literal: true

module Submissions
  module SerializeForApi
    SERIALIZE_PARAMS = {
      only: %i[id slug source submitters_order created_at updated_at archived_at],
      methods: %i[audit_log_url],
      include: {
        submitters: { only: %i[id slug uuid name email phone
                               completed_at opened_at sent_at
                               created_at updated_at external_id metadata],
                      methods: %i[status application_key] },
        template: { only: %i[id name external_id created_at updated_at],
                    methods: %i[folder_name] },
        created_by_user: { only: %i[id email first_name last_name] }
      }
    }.freeze

    module_function

    def call(submission, submitters = nil, params = {})
      submitters ||= submission.submitters.preload(documents_attachments: :blob, attachments_attachments: :blob)

      serialized_submitters = submitters.map { |submitter| Submitters::SerializeForApi.call(submitter, params:) }

      json = submission.as_json(
        SERIALIZE_PARAMS.deep_merge(
          include: { submission_events: { only: %i[id submitter_id event_type event_timestamp] } }
        )
      )

      if submitters.all?(&:completed_at?)
        last_submitter = submitters.max_by(&:completed_at)

        if params[:include].to_s.include?('combined_document_url')
          json[:combined_document_url] = build_combined_url(submitters.max_by(&:completed_at), submission)
        end

        json[:documents] = serialized_submitters.find { |e| e['id'] == last_submitter.id }['documents']
        json[:status] = 'completed'
        json[:completed_at] = last_submitter.completed_at
      else
        json[:documents] = []
        json[:status] = 'pending'
        json[:completed_at] = nil
      end

      json[:submitters] = serialized_submitters

      json
    end

    def build_combined_url(submitter, submission)
      return unless submitter.completed_at?

      attachment = submission.combined_document_attachment
      attachment ||= Submissions::GenerateCombinedAttachment.call(submitter)

      ActiveStorage::Blob.proxy_url(attachment.blob)
    end
  end
end
