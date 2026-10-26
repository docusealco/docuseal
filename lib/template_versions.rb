# frozen_string_literal: true

module TemplateVersions
  SERIALIZE_PARAMS = {
    only: %i[id created_at],
    include: { author: { only: %i[email], methods: %i[full_name] } }
  }.freeze

  DATA_FIELDS = %i[name schema submitters variables_schema fields].freeze

  module_function

  def find_or_create_for(template, author:)
    data = build_data(template)
    sha1 = Digest::SHA1.hexdigest(data.to_json)

    version   = template.template_versions.find_by(sha1:)
    version ||= template.template_versions.create!(data:, sha1:, author:)

    version
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def serialize(version)
    data = version.data.dup

    data['documents'] = serialize_documents(version.template, data['schema'].to_a)
    data['dynamic_documents'] = serialize_dynamic_documents(version.template, data['dynamic_documents'].to_a)

    version.as_json(SERIALIZE_PARAMS).merge('data' => data)
  end

  def build_data(template)
    dynamic_uuids = template.schema.select { |e| e['dynamic'] }.pluck('attachment_uuid')

    dynamic_documents =
      if dynamic_uuids.present?
        template.dynamic_documents.where(uuid: dynamic_uuids).as_json(only: %i[uuid body])
      else
        []
      end

    template.as_json(only: DATA_FIELDS).merge('dynamic_documents' => dynamic_documents)
  end

  def serialize_documents(template, schema)
    return [] if schema.blank?

    template.documents_attachments
            .where(uuid: schema.pluck('attachment_uuid'))
            .preload(:blob, preview_images_attachments: :blob)
            .as_json(
              only: %i[id uuid],
              methods: %i[metadata signed_key],
              include: { preview_images: { only: %i[id], methods: %i[url metadata filename] } }
            )
  end

  def serialize_dynamic_documents(template, dynamic_docs)
    return [] if dynamic_docs.blank?

    dynamic_docs_index = template.dynamic_documents
                                 .where(uuid: dynamic_docs.pluck('uuid'))
                                 .preload(attachments_attachments: :blob)
                                 .index_by(&:uuid)

    dynamic_docs.map do |attrs|
      document = dynamic_docs_index[attrs['uuid']]

      attachments_data = document.attachments_attachments.as_json(only: %i[uuid], methods: %i[url metadata filename])

      attrs.merge('head' => document.head, 'attachments' => attachments_data)
    end
  end
end
