# frozen_string_literal: true

module Templates
  module CloneAttachments
    module_function

    def call(template:, original_template:)
      schema_uuids_replacements = {}

      cloned_schema = original_template['schema'].deep_dup
      cloned_fields = template['fields'].deep_dup

      cloned_schema.each do |schema_item|
        new_schema_item_uuid = SecureRandom.uuid

        schema_uuids_replacements[schema_item['attachment_uuid']] = new_schema_item_uuid
        schema_item['attachment_uuid'] = new_schema_item_uuid
      end

      cloned_fields.each do |field|
        next if field['areas'].blank?

        field['areas'].each do |area|
          area['attachment_uuid'] = schema_uuids_replacements[area['attachment_uuid']]
        end
      end

      template.update!(schema: cloned_schema, fields: cloned_fields)

      original_template.schema_documents.preload(:preview_images_attachments).each do |document|
        new_document = ActiveStorage::Attachment.create!(
          uuid: schema_uuids_replacements[document.uuid],
          blob_id: document.blob_id,
          name: 'documents',
          record: template
        )

        clone_document_preview_images_attachments(document:, new_document:)
      end
    end

    def clone_document_preview_images_attachments(document:, new_document:)
      ApplicationRecord.no_touching do
        document.preview_images_attachments.each do |preview_image|
          ActiveStorage::Attachment.create!(
            blob_id: preview_image.blob_id,
            name: 'preview_images',
            record: new_document
          )
        end
      end
    end
  end
end
