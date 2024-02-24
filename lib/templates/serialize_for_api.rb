# frozen_string_literal: true

module Templates
  module SerializeForApi
    module_function

    def call(template, schema_documents = template.schema_documents, preview_image_attachments = [])
      json = template.as_json(
        methods: %i[application_key],
        include: { author: { only: %i[id email first_name last_name] } }
      )

      json[:folder_name] = template.folder.name

      json[:documents] = template.schema.map do |item|
        attachment = schema_documents.find { |e| e.uuid == item['attachment_uuid'] }

        first_page_blob = preview_image_attachments.find { |e| e.record_id == attachment.id }&.blob
        first_page_blob ||= attachment.preview_images.joins(:blob).find_by(blob: { filename: '0.jpg' })&.blob

        {
          id: attachment.id,
          uuid: attachment.uuid,
          url: ActiveStorage::Blob.proxy_url(attachment.blob),
          preview_image_url: first_page_blob && ActiveStorage::Blob.proxy_url(first_page_blob),
          filename: attachment.filename
        }
      end

      json
    end
  end
end
