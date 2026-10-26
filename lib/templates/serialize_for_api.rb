# frozen_string_literal: true

module Templates
  module SerializeForApi
    SERIALIZE_PARAMS = {
      only: %w[
        id name slug schema submitters fields variables_schema
        preferences source created_at updated_at archived_at author_id
        external_id folder_id shared_link
      ],
      methods: %i[application_key folder_name],
      include: { author: { only: %i[id email first_name last_name] } }
    }.freeze

    module_function

    def call(template, schema_documents: template.schema_documents.preload(:blob), dynamic_documents: nil,
             preview_image_attachments: nil, expires_at: Accounts.link_expires_at(Account.new(id: template.account_id)))
      json = template.as_json(SERIALIZE_PARAMS)

      dynamic_documents ||= preload_dynamic_documents(template)

      preview_image_attachments ||= preload_preview_image_attachments(schema_documents, dynamic_documents)

      json['variables_schema'] ||= {}

      json['documents'] = build_documents_array(template, schema_documents, dynamic_documents,
                                                preview_image_attachments, expires_at)

      json
    end

    def build_documents_array(template, schema_documents, dynamic_documents, preview_image_attachments, expires_at)
      template.schema.filter_map do |item|
        if item['dynamic']
          dynamic_document = dynamic_documents.find { |e| e.uuid == item['attachment_uuid'] }

          attachment = dynamic_document.current_version&.document_attachment
        end

        attachment ||= schema_documents.find { |e| e.uuid == item['attachment_uuid'] }

        next unless attachment

        first_page_blob = preview_image_attachments.find { |e| e.record_id == attachment.id }&.blob
        first_page_blob ||= attachment.preview_images.joins(:blob).find_by(blob: { filename: ['0.jpg', '0.png'] })&.blob

        {
          'id' => attachment.id,
          'uuid' => attachment.uuid,
          'url' => ActiveStorage::Blob.proxy_url(attachment.blob, expires_at:),
          'preview_image_url' => first_page_blob && ActiveStorage::Blob.proxy_url(first_page_blob, expires_at:),
          'filename' => attachment.filename
        }
      end
    end

    def preload_dynamic_documents(template)
      return DynamicDocument.none if template.schema.none? { |item| item['dynamic'] }

      template.schema_dynamic_documents
              .preload(current_version: { document_attachment: :blob })
              .select(:id, :uuid, :template_id, :sha1, :created_at, :updated_at)
    end

    def preload_preview_image_attachments(schema_documents, dynamic_documents)
      record_ids =
        schema_documents.map(&:id) +
        dynamic_documents.filter_map { |d| d.current_version&.document_attachment&.id }

      ActiveStorage::Attachment.joins(:blob)
                               .where(blob: { filename: ['0.jpg', '0.png'] })
                               .where(record_id: record_ids,
                                      record_type: 'ActiveStorage::Attachment',
                                      name: :preview_images)
                               .preload(:blob)
    end
  end
end
