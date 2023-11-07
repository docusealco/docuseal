# frozen_string_literal: true

module Templates
  module CloneAttachments
    module_function

    def call(template:, original_template:)
      original_template.documents.preload(:preview_images_attachments).each do |document|
        new_document = ActiveStorage::Attachment.create!(
          uuid: document.uuid,
          blob_id: document.blob_id,
          name: 'documents',
          record: template
        )

        ApplicationRecord.no_touching do
          document.preview_images_attachments.each do |preview_image|
            ActiveStorage::Attachment.create!(
              uuid: preview_image.uuid,
              blob_id: preview_image.blob_id,
              name: 'preview_images',
              record: new_document
            )
          end
        end
      end
    end
  end
end
