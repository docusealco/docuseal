# frozen_string_literal: true

class GenerateAttachmentPreviewJob
  include Sidekiq::Job

  InvalidFormat = Class.new(StandardError)

  sidekiq_options queue: :images

  def perform(params = {})
    attachment = ActiveStorage::Attachment.find(params['attachment_id'])

    if attachment.content_type == Templates::ProcessDocument::PDF_CONTENT_TYPE
      Templates::ProcessDocument.generate_pdf_preview_images(attachment, attachment.download)
    elsif attachment.image?
      Templates::ProcessDocument.generate_preview_image(attachment, attachment.download)
    else
      raise InvalidFormat, attachment.id
    end
  end
end
