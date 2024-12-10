# frozen_string_literal: true

module Templates
  module CloneAttachments
    module_function

    def call(template:, original_template:, documents: [])
      schema_uuids_replacements = {}

      template.schema.each_with_index do |schema_item, index|
        new_schema_item_uuid = SecureRandom.uuid

        schema_uuids_replacements[schema_item['attachment_uuid']] = new_schema_item_uuid
        schema_item['attachment_uuid'] = new_schema_item_uuid

        new_name = documents&.dig(index, 'name')

        schema_item['name'] = new_name if new_name.present?
      end

      template.fields.each do |field|
        next if field['areas'].blank?

        field['areas'].each do |area|
          area['attachment_uuid'] = schema_uuids_replacements[area['attachment_uuid']]
        end
      end

      template.save!

      original_template.schema_documents.map do |document|
        new_document =
          ApplicationRecord.no_touching do
            template.documents_attachments.create!(
              uuid: schema_uuids_replacements[document.uuid],
              blob_id: document.blob_id
            )
          end

        clone_document_preview_images_attachments(document:, new_document:)

        new_document
      end
    end

    def clone_document_preview_images_attachments(document:, new_document:)
      ApplicationRecord.no_touching do
        document.preview_images_attachments.each do |preview_image|
          new_document.preview_images_attachments.create!(blob_id: preview_image.blob_id)
        end
      end
    end
  end
end
