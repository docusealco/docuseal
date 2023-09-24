# frozen_string_literal: true

module Submitters
  module NormalizeValues
    CHECKSUM_CACHE_STORE = ActiveSupport::Cache::MemoryStore.new

    UnknownFieldName = Class.new(StandardError)
    UnknownSubmitterName = Class.new(StandardError)

    module_function

    def call(template, values, submitter_name)
      submitter =
        template.submitters.find { |e| e['name'] == submitter_name } ||
        raise(UnknownSubmitterName, "Unknown submitter: #{submitter_name}")

      fields = template.fields.select { |e| e['submitter_uuid'] == submitter['uuid'] }

      fields_uuid_index = fields.index_by { |e| e['uuid'] }
      fields_name_index = build_fields_index(fields)

      attachments = []

      normalized_values = values.to_h.to_h do |key, value|
        if fields_uuid_index[key].blank?
          key = fields_name_index[key]&.dig('uuid') || raise(UnknownFieldName, "Unknown field: #{key}")
        end

        if fields_uuid_index[key]['type'].in?(%w[initials signature image file])
          new_value, new_attachments = normalize_attachment_value(value, template.account)

          attachments.push(*new_attachments)

          value = new_value
        end

        [key, value]
      end

      [normalized_values, attachments]
    end

    def build_fields_index(fields)
      fields.index_by { |e| e['name'] }.merge(fields.index_by { |e| e['name'].parameterize.underscore })
    end

    def normalize_attachment_value(value, account)
      if value.is_a?(Array)
        new_attachments = value.map { |v| build_attachment(v, account) }

        [new_attachments.map(&:uuid), new_attachments]
      else
        new_attachment = build_attachment(value, account)

        [new_attachment.uuid, new_attachment]
      end
    end

    def build_attachment(value, account)
      ActiveStorage::Attachment.new(
        blob: find_or_create_blobs(account, value),
        name: 'attachments'
      )
    end

    def find_or_create_blobs(account, url)
      cache_key = [account.id, url].join(':')
      checksum = CHECKSUM_CACHE_STORE.fetch(cache_key)

      blob = find_blob_by_checksum(checksum, account) if checksum

      return blob if blob

      data = conn.get(url).body

      checksum = Digest::MD5.base64digest(data)

      CHECKSUM_CACHE_STORE.write(cache_key, checksum)

      blob = find_blob_by_checksum(checksum, account)

      blob || ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: Addressable::URI.parse(url).path.split('/').last
      )
    end

    def find_blob_by_checksum(checksum, account)
      ActiveStorage::Blob
        .joins('JOIN active_storage_attachments ON active_storage_attachments.blob_id = active_storage_blobs.id')
        .where(active_storage_attachments: { record_id: account.submitters.select(:id),
                                             record_type: 'Submitter' })
        .find_by(checksum:)
    end

    def conn
      Faraday.new do |faraday|
        faraday.response :follow_redirects
      end
    end
  end
end
