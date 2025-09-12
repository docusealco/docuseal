# frozen_string_literal: true

module Submissions
  module SerializeForApi
    SERIALIZE_PARAMS = {
      only: %i[id name slug source submitters_order expire_at created_at updated_at archived_at],
      include: {
        submitters: { only: %i[id] },
        template: { only: %i[id name external_id created_at updated_at],
                    methods: %i[folder_name] },
        created_by_user: { only: %i[id email first_name last_name] }
      }
    }.freeze

    module_function

    def call(submission, submitters = nil, params = {}, with_events: true, with_documents: true, with_values: true,
             expires_at: Accounts.link_expires_at(Account.new(id: submission.account_id)))
      submitters ||= submission.submitters.preload(documents_attachments: :blob, attachments_attachments: :blob)

      serialized_submitters = submitters.map do |submitter|
        Submitters::SerializeForApi.call(submitter, with_documents:, with_events: false, with_values:, params:,
                                                    expires_at:)
      end

      json = submission.as_json(SERIALIZE_PARAMS)

      json['variables'] = (submission.variables || {}).as_json
      json['created_by_user'] ||= nil

      if with_events
        json['submission_events'] = Submitters::SerializeForApi.serialize_events(submission.submission_events)
      end

      if submitters.all?(&:completed_at?)
        last_submitter = submitters.max_by(&:completed_at)

        if with_documents
          json['documents'] = serialized_submitters.find { |e| e['id'] == last_submitter.id }['documents']
        end

        json['audit_log_url'] = submission.audit_log_url(expires_at:)
        json['combined_document_url'] = submission.combined_document_url(expires_at:)
        json['combined_document_url'] ||= maybe_build_combined_url(submitters, submission, params, expires_at:)

        json['status'] = 'completed'
        json['completed_at'] = last_submitter.completed_at.as_json
      else
        json['documents'] = [] if with_documents
        json['audit_log_url'] = nil
        json['combined_document_url'] = nil
        json['status'] = build_status(submission, submitters)
        json['completed_at'] = nil
      end

      json['submitters'] = serialized_submitters

      json
    end

    def build_status(submission, submitters)
      if submitters.any?(&:declined_at?)
        'declined'
      else
        submission.expired? ? 'expired' : 'pending'
      end
    end

    def maybe_build_combined_url(submitters, submission, params, expires_at: nil)
      return unless submitters.all?(&:completed_at?)

      attachment = submission.combined_document_attachment

      if !attachment && params[:include].to_s.include?('combined_document_url')
        submitter = submitters.max_by(&:completed_at)

        attachment = Submissions::GenerateCombinedAttachment.call(submitter)
      end

      ActiveStorage::Blob.proxy_url(attachment.blob, expires_at:) if attachment
    end
  end
end
