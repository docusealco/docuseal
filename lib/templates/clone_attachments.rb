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
            template.documents_attachments.new(uuid: new_attachment_uuid, blob_id: document.blob_id)

          maybe_clone_dynamic_document(template, original_template, new_document, document)
          clone_document_preview_images_attachments(document:, new_document:)

          new_document
        end

      template.save! if save

      attachments
    end

    def maybe_clone_dynamic_document(template, original_template, document, original_document)
      schema_item = original_template.schema.find { |e| e['attachment_uuid'] == original_document.uuid }

      return unless schema_item
      return unless schema_item['dynamic']

      dynamic_document = original_template.dynamic_documents.find { |e| e.uuid == original_document.uuid }

      return unless dynamic_document

      new_dynamic_document = template.dynamic_documents.new(
        uuid: document.uuid,
        body: dynamic_document.body,
        head: dynamic_document.head
      )

      dynamic_document.attachments_attachments.each do |attachment|
        new_dynamic_document.attachments_attachments.new(
          uuid: attachment.uuid,
          blob_id: attachment.blob_id
        )
      end

      new_dynamic_document
    end

    def clone_document_preview_images_attachments(document:, new_document:)
      document.preview_images_attachments.each do |preview_image|
        new_document.preview_images_attachments.new(blob_id: preview_image.blob_id)
      end
    end
  end
end
