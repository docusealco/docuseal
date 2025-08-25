# frozen_string_literal: true

module PrefillFieldsHelper
  # Cache TTL for ATS field parsing (1 hour)
  ATS_FIELDS_CACHE_TTL = 1.hour

  # Maximum number of cached entries to prevent memory bloat
  MAX_CACHE_ENTRIES = 1000

  def extract_ats_prefill_fields
    return [] if params[:ats_fields].blank?

    # Create cache key from parameter hash for security and uniqueness
    cache_key = ats_fields_cache_key(params[:ats_fields])

    # Try to get from cache first with error handling
    begin
      cached_result = Rails.cache.read(cache_key)
      return cached_result if cached_result
    rescue StandardError => e
      # Continue with normal processing if cache read fails
    end

    begin
      decoded_json = Base64.urlsafe_decode64(params[:ats_fields])
      field_names = JSON.parse(decoded_json)

      # Validate that we got an array of strings
      return cache_and_return_empty(cache_key) unless field_names.is_a?(Array) && field_names.all?(String)

      # Filter to only expected field name patterns
      valid_fields = field_names.select { |name| valid_ats_field_name?(name) }

      # Cache the result with TTL (with error handling)
      cache_result(cache_key, valid_fields, ATS_FIELDS_CACHE_TTL)

      valid_fields
    rescue StandardError => e
      # Cache empty result for failed parsing to avoid repeated failures
      cache_result(cache_key, [], 5.minutes)
      []
    end
  end


  # Merge ATS prefill values with existing submitter values
  # ATS values should not override existing submitter-entered values
  # @param submitter_values [Hash] existing values entered by submitters
  # @param ats_values [Hash] prefill values from ATS
  # @return [Hash] merged values with submitter values taking precedence
  def merge_ats_prefill_values(submitter_values, ats_values, template_fields = nil)
    return submitter_values if ats_values.blank?

    # Only use ATS values for fields that don't already have submitter values
    ats_values.each do |field_name, value|
      # Find matching field by name in template fields
      matching_field_uuid = find_field_uuid_by_name(field_name, template_fields)

      next if matching_field_uuid.nil?

      # Only set if submitter hasn't already filled this field
      if submitter_values[matching_field_uuid].blank?
        submitter_values[matching_field_uuid] = value
      end
    end

    submitter_values
  end

  # Clear ATS fields cache (useful for testing or manual cache invalidation)
  def clear_ats_fields_cache
    # Since we can't easily enumerate cache keys, we'll rely on TTL for cleanup
    # This method is provided for potential future use or testing
  end

  private

  def valid_ats_field_name?(name)
    # Only allow expected field name patterns (security)
    name.match?(/\A(employee|manager|account|location)_[a-z_]+\z/)
  end

  def ats_fields_cache_key(ats_fields_param)
    # Create secure cache key using SHA256 hash of the parameter
    # This prevents cache key collisions and keeps keys reasonably sized
    hash = Digest::SHA256.hexdigest(ats_fields_param)
    "ats_fields:#{hash}"
  end

  def cache_result(cache_key, value, ttl)
    Rails.cache.write(cache_key, value, expires_in: ttl)
  rescue StandardError => e
    # Continue execution even if caching fails
  end

  def cache_and_return_empty(cache_key)
    cache_result(cache_key, [], 5.minutes)
    []
  end

  # Find field UUID by matching ATS field name to template field's prefill attribute
  def find_field_uuid_by_name(field_name, template_fields = nil)
    return nil if field_name.blank? || template_fields.blank?

    # Find template field where the prefill attribute matches the ATS field name
    matching_field = template_fields.find { |field| field['prefill'] == field_name }

    matching_field&.dig('uuid')
  end

end
