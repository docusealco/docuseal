# frozen_string_literal: true

class GeneratePreviewImagesJob
  include Sidekiq::Job

  sidekiq_options queue: :images

  def perform(params = {})
    attachment = ActiveStorage::Attachment.find(params['attachment_id'])

    max_page = [attachment.metadata['pdf']['number_of_pages'].to_i - 1,
                Templates::ProcessDocument::MAX_NUMBER_OF_PAGES_PROCESSED].min

    Templates::ProcessDocument.generate_document_preview_images(attachment, attachment.download, (1..max_page),
                                                                concurrency: 1)
  end
end
