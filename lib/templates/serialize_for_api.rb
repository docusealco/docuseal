# frozen_string_literal: true

module Templates
  module SerializeForApi
    SERIALIZE_PARAMS = {
      only: %w[
        id archived_at fields name preferences schema
        slug source submitters created_at updated_at
        author_id external_id folder_id shared_link
      ],
      methods: %i[application_key folder_name],
      include: { author: { only: %i[id email first_name last_name] } }
    }.freeze

    module_function

    def call(template, schema_documents = template.schema_documents.preload(:blob), preview_image_attachments = nil)
      json = template.as_json(SERIALIZE_PARAMS)

      preview_image_attachments ||=
        ActiveStorage::Attachment.joins(:blob)
                                 .where(blob: { filename: ['0.jpg', '0.png'] })
                                 .where(record_id: schema_documents.map(&:id),
                                        record_type: 'ActiveStorage::Attachment',
                                        name: :preview_images)
                                 .preload(:blob)

      json[:documents] = template.schema.filter_map do |item|
        attachment = schema_documents.find { |e| e.uuid == item['attachment_uuid'] }

        unless attachment
          Rollbar.error("Documents missing: #{template.id}") if defined?(Rollbar)

          next
        end

        first_page_blob = preview_image_attachments.find { |e| e.record_id == attachment.id }&.blob
        first_page_blob ||= attachment.preview_images.joins(:blob).find_by(blob: { filename: ['0.jpg', '0.png'] })&.blob

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
