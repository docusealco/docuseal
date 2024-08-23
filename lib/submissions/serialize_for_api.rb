# frozen_string_literal: true

module Submissions
  module SerializeForApi
    SERIALIZE_PARAMS = {
      only: %i[id slug source submitters_order expire_at created_at updated_at archived_at],
      methods: %i[audit_log_url combined_document_url],
      include: {
        submitters: { only: %i[id slug uuid name email phone
                               completed_at opened_at sent_at declined_at
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

      json = submission.as_json(SERIALIZE_PARAMS)

      json['submission_events'] = Submitters::SerializeForApi.serialize_events(submission.submission_events)
      json['combined_document_url'] ||= maybe_build_combined_url(submitters, submission, params)

      if submitters.all?(&:completed_at?)
        last_submitter = submitters.max_by(&:completed_at)

        json[:documents] = serialized_submitters.find { |e| e['id'] == last_submitter.id }['documents']
        json[:status] = 'completed'
        json[:completed_at] = last_submitter.completed_at
      else
        json[:documents] = []
        json[:status] = if submitters.any?(&:declined_at?)
                          'declined'
                        else
                          submission.expired? ? 'expired' : 'pending'
                        end
        json[:completed_at] = nil
      end

      json[:submitters] = serialized_submitters

      json
    end

    def maybe_build_combined_url(submitters, submission, params)
      return unless submitters.all?(&:completed_at?)

      attachment = submission.combined_document_attachment

      if !attachment && params[:include].to_s.include?('combined_document_url')
        submitter = submitters.max_by(&:completed_at)

        attachment = Submissions::GenerateCombinedAttachment.call(submitter)
      end

      ActiveStorage::Blob.proxy_url(attachment.blob) if attachment
    end
  end
end
