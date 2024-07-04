# frozen_string_literal: true

module Submitters
  module NormalizeValues
    CHECKSUM_CACHE_STORE = ActiveSupport::Cache::MemoryStore.new

    BaseError = Class.new(StandardError)

    UnknownFieldName = Class.new(BaseError)
    InvalidDefaultValue = Class.new(BaseError)
    UnknownSubmitterName = Class.new(BaseError)
    UnableToDownload = Class.new(BaseError)

    TRUE_VALUES = ['1', 'true', true, 'TRUE', 'True', 'yes', 'YES', 'Yes'].freeze
    FALSE_VALUES = ['0', 'false', false, 'FALSE', 'False', 'no', 'NO', 'No'].freeze

    module_function

    def call(template, values, submitter_name: nil, for_submitter: nil, throw_errors: false)
      fields = fetch_fields(template, submitter_name:, for_submitter:)

      fields_uuid_index = fields.index_by { |e| e['uuid'] }
      fields_name_index = build_fields_index(fields)

      attachments = []

      normalized_values = values.to_h.filter_map do |key, value|
        if fields_uuid_index[key].blank?
          original_key = key

          key = fields_name_index[key]&.dig('uuid') || fields_name_index[key.to_s.downcase]&.dig('uuid')

          raise(UnknownFieldName, "Unknown field: #{original_key}") if key.blank? && throw_errors
        end

        next if key.blank?

        field = fields_uuid_index[key]

        if field['type'].in?(%w[initials signature image file stamp]) && value.present?
          new_value, new_attachments =
            normalize_attachment_value(value, field['type'], template.account, attachments, for_submitter)

          attachments.push(*new_attachments)

          value = new_value
        end

        [key, normalize_value(field, value)]
      end.to_h

      [normalized_values, attachments]
    end

    def normalize_value(field, value)
      if field['type'] == 'checkbox'
        return true if TRUE_VALUES.include?(value)
        return false if FALSE_VALUES.include?(value)
      end

      return nil if value.blank?

      if field['type'] == 'text'
        value.to_s
      elsif field['type'] == 'number'
        (value.to_f % 1).zero? ? value.to_i : value.to_f
      elsif field['type'] == 'date' && value != '{{date}}'
        normalize_date(field, value)
      else
        value
      end
    end

    def normalize_date(field, value)
      if value.is_a?(Integer)
        Time.zone.at(value.to_s.first(10).to_i).to_date.to_s
      elsif value.gsub(/\w/, '0') == field.dig('preferences', 'format').to_s.gsub(/\w/, '0')
        TimeUtils.parse_date_string(value, field.dig('preferences', 'format')).to_s
      else
        Date.parse(value).to_s
      end
    rescue Date::Error => e
      Rollbar.warning(e) if defined?(Rollbar)

      value
    end

    def fetch_fields(template, submitter_name: nil, for_submitter: nil)
      if submitter_name
        submitter =
          template.submitters.find { |e| e['name'] == submitter_name } ||
          raise(UnknownSubmitterName,
                "Unknown submitter role: #{submitter_name}. Template defines #{template.submitters.pluck('name')}")
      end

      fields = for_submitter&.submission&.template_fields || template.fields

      fields.select do |e|
        submitter_uuid =
          for_submitter&.uuid || submitter&.dig('uuid') ||
          raise(UnknownSubmitterName, "Unknown submitter role: template defines #{template.submitters.pluck('name')}")

        e['submitter_uuid'] == submitter_uuid
      end
    end

    def build_fields_index(fields)
      fields.index_by { |e| e['name'] }
            .merge(fields.index_by { |e| e['name'].to_s.parameterize.underscore })
            .merge(fields.index_by { |e| e['name'].to_s.downcase })
    end

    def normalize_attachment_value(value, type, account, attachments, for_submitter = nil)
      if value.is_a?(Array)
        new_attachments = value.map do |v|
          new_attachment = find_or_build_attachment(v, type, account, for_submitter)

          attachments.find { |a| a.blob_id == new_attachment.blob_id } || new_attachment
        end

        [new_attachments.map(&:uuid), new_attachments]
      else
        new_attachment = find_or_build_attachment(value, type, account, for_submitter)

        existing_attachment = attachments.find { |a| a.blob_id == new_attachment.blob_id }

        attachment = existing_attachment || new_attachment

        [attachment.uuid, attachment]
      end
    end

    def find_or_build_attachment(value, type, account, for_submitter = nil)
      blob =
        if value.match?(%r{\Ahttps?://})
          find_or_create_blob_from_url(account, value)
        elsif type.in?(%w[signature initials]) && value.length < 60
          find_or_create_blob_from_text(account, value, type)
        elsif (data = Base64.decode64(value)) && Marcel::MimeType.for(data).include?('image')
          find_or_create_blob_from_base64(account, data, type)
        else
          raise InvalidDefaultValue, "Invalid value, url, base64 or text < 60 chars is expected: #{value.first(200)}..."
        end

      attachment = for_submitter.attachments.find_by(blob_id: blob.id) if for_submitter

      attachment ||= ActiveStorage::Attachment.new(
        blob:,
        name: 'attachments'
      )

      attachment
    end

    def find_or_create_blob_from_base64(account, data, type)
      checksum = Digest::MD5.base64digest(data)

      blob = find_blob_by_checksum(checksum, account)

      blob || ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: "#{type}.png"
      )
    end

    def find_or_create_blob_from_text(account, text, type)
      data = Submitters::GenerateFontImage.call(text, font: type)

      checksum = Digest::MD5.base64digest(data)

      blob = find_blob_by_checksum(checksum, account)

      blob || ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: "#{type}.png"
      )
    end

    def find_or_create_blob_from_url(account, url)
      cache_key = [account.id, url].join(':')
      checksum = CHECKSUM_CACHE_STORE.fetch(cache_key)

      blob = find_blob_by_checksum(checksum, account) if checksum

      return blob if blob

      uri = Addressable::URI.parse(url)
      resp = conn.get(uri.display_uri.to_s)

      raise UnableToDownload, "Error loading: #{uri.display_uri}" if resp.status >= 400

      data = resp.body

      checksum = Digest::MD5.base64digest(data)

      CHECKSUM_CACHE_STORE.write(cache_key, checksum)

      blob = find_blob_by_checksum(checksum, account)

      blob || ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(data),
        filename: Addressable::URI.parse(url).path.split('/').last
      )
    end

    def find_blob_by_checksum(checksum, account)
      blob = ActiveStorage::Blob.find_by(checksum:)

      return unless blob

      return blob unless blob.attachments.exists?

      return blob if account.submitters.exists?(id: blob.attachments.where(record_type: 'Submitter').select(:record_id))

      nil
    end

    def conn
      Faraday.new do |faraday|
        faraday.response :follow_redirects
      end
    end
  end
end
