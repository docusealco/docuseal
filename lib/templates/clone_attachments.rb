# frozen_string_literal: true

module Templates
  module CloneAttachments
    module_function

    def call(template:, original_template:, documents: [], excluded_attachment_uuids: [], save: true)
      schema_uuids_replacements = {}

      template.schema.each_with_index do |schema_item, index|
        next if excluded_attachment_uuids.include?(schema_item['attachment_uuid'])

        new_schema_item_uuid = SecureRandom.uuid

        schema_uuids_replacements[schema_item['attachment_uuid']] = new_schema_item_uuid
        schema_item['attachment_uuid'] = new_schema_item_uuid

        new_name = documents&.dig(index, 'name')

        schema_item['name'] = new_name if new_name.present?
      end

      template.fields.each do |field|
        next if field['areas'].blank?

        field['areas'].each do |area|
          new_attachment_uuid = schema_uuids_replacements[area['attachment_uuid']]
          area['attachment_uuid'] = new_attachment_uuid if new_attachment_uuid
        end
      end

      attachments =
        original_template.schema_documents.filter_map do |document|
          new_attachment_uuid = schema_uuids_replacements[document.uuid]

          next unless new_attachment_uuid

          new_document =
            template.documents_attachments.new(
              uuid: new_attachment_uuid,
              blob_id: document.blob_id
            )

          clone_document_preview_images_attachments(document:, new_document:)

          new_document
        end

      template.save! if save

      attachments
    end

    def clone_document_preview_images_attachments(document:, new_document:)
      document.preview_images_attachments.each do |preview_image|
        new_document.preview_images_attachments.new(blob_id: preview_image.blob_id)
      end
    end
  end
end
