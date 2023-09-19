# frozen_string_literal: true

module Submitters
  module_function

  def search(submitters, keyword)
    return submitters if keyword.blank?

    term = "%#{keyword.downcase}%"

    arel_table = Submitter.arel_table

    arel = arel_table[:email].lower.matches(term)
                             .or(arel_table[:phone].matches(term))
                             .or(arel_table[:name].lower.matches(term))

    submitters.where(arel)
  end

  def select_attachments_for_download(submitter)
    original_documents = submitter.submission.template.documents.preload(:blob)
    is_more_than_two_images = original_documents.count(&:image?) > 1

    submitter.documents.preload(:blob).reject do |attachment|
      is_more_than_two_images && original_documents.find { |a| a.uuid == attachment.uuid }&.image?
    end
  end

  def create_attachment!(submitter, params)
    blob =
      if (file = params[:file])
        ActiveStorage::Blob.create_and_upload!(io: file.open,
                                               filename: file.original_filename,
                                               content_type: file.content_type)
      else
        ActiveStorage::Blob.find_signed(params[:blob_signed_id])
      end

    ActiveStorage::Attachment.create!(
      blob:,
      name: params[:name],
      record: submitter
    )
  end

  def send_signature_requests(submitters, params)
    return if params[:send_email] != true && params[:send_email] != '1'

    submitters.each do |submitter|
      next if submitter.email.blank?

      enqueue_invitation_email(submitter, params)
    end
  end

  def enqueue_invitation_email(submitter, params)
    subject, body = params.values_at(:subject, :body) if params[:is_custom_message] == '1'

    SendSubmitterInvitationEmailJob.perform_later('submitter_id' => submitter.id,
                                                  'body' => body,
                                                  'subject' => subject)
  end
end
