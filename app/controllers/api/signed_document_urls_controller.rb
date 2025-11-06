# frozen_string_literal: true

module Api
  class SignedDocumentUrlsController < ApiBaseController
    load_and_authorize_resource :submission

    def show
      # Find the last completed submitter
      last_submitter = @submission.submitters
                                  .where.not(completed_at: nil)
                                  .order(:completed_at)
                                  .last

      return render json: { error: 'Submission not completed' },
                    status: :unprocessable_entity if last_submitter.blank?

      # Ensure documents are generated
      Submissions::EnsureResultGenerated.call(last_submitter)

      # Build signed URLs using standard DocuSeal configuration
      documents = build_signed_urls(last_submitter)

      render json: {
        submission_id: @submission.id,
        submitter_id: last_submitter.id,
        documents: documents
      }
    end

    private

    def build_signed_urls(submitter)
      Submitters.select_attachments_for_download(submitter).map do |attachment|
        {
          name: attachment.filename.to_s,
          url: generate_url(attachment),
          size_bytes: attachment.blob.byte_size,
          content_type: attachment.blob.content_type
        }
      end
    end

    def generate_url(attachment)
      if uses_secured_storage?(attachment)
        # CloudFront signed URL with 1 hour expiration (default)
        DocumentSecurityService.signed_url_for(attachment)
      else
        # Standard ActiveStorage proxy URL with 1 hour expiration
        ActiveStorage::Blob.proxy_url(
          attachment.blob,
          expires_at: 1.hour.from_now.to_i
        )
      end
    end

    def uses_secured_storage?(attachment)
      attachment.blob.service_name == 'aws_s3_secured'
    end
  end
end
