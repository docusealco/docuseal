# frozen_string_literal: true

module Api
  class SubmissionDocumentsController < ApiBaseController
    load_and_authorize_resource :submission

    def index
      documents =
        if @submission.submitters.all?(&:completed_at?)
          last_submitter = @submission.submitters.max_by(&:completed_at)

          if last_submitter.documents_attachments.blank?
            last_submitter.documents_attachments = Submissions::EnsureResultGenerated.call(last_submitter)
          end

          last_submitter.documents_attachments
        else
          values_hash = Submissions::GeneratePreviewAttachments.build_values_hash(@submission)

          if @submission.preview_documents.present? &&
             @submission.preview_documents.all? { |s| s.metadata['values_hash'] == values_hash }
            @submission.preview_documents
          else
            ApplicationRecord.no_touching do
              @submission.preview_documents.each(&:destroy)
            end

            Submissions::GeneratePreviewAttachments.call(@submission, values_hash:)
          end
        end

      ActiveRecord::Associations::Preloader.new(
        records: documents,
        associations: [:blob]
      ).call

      render json: {
        id: @submission.id,
        documents: documents.map do |attachment|
          { name: attachment.filename.base, url: ActiveStorage::Blob.proxy_url(attachment.blob) }
        end
      }
    end
  end
end
