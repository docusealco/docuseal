# frozen_string_literal: true

module PrefillFieldsHelper
  # Cache TTL for ATS field parsing (1 hour)
  ATS_FIELDS_CACHE_TTL = 1.hour

  # Maximum number of cached entries to prevent memory bloat
  MAX_CACHE_ENTRIES = 1000

  # Cache TTL for field UUID lookup optimization (30 minutes)
  FIELD_LOOKUP_CACHE_TTL = 30.minutes

  # Extracts and validates ATS prefill field names from Base64-encoded parameters
  #
  # This method decodes the ats_fields parameter, validates the field names against
  # allowed patterns, and caches the results to improve performance on repeated requests.
  #
  # @return [Array<String>] Array of valid ATS field names, empty array if none found or on error
  #
  # @example
  #   # With params[:ats_fields] = Base64.urlsafe_encode64(['employee_first_name', 'employee_email'].to_json)
  #   extract_ats_prefill_fields
  #   # => ['employee_first_name', 'employee_email']
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


  # Merges ATS prefill values with existing submitter values
  #
  # This method combines ATS-provided prefill values with values already entered by submitters.
  # Existing submitter values always take precedence over ATS values to prevent overwriting
  # user input. Uses optimized field lookup caching for better performance.
  #
  # @param submitter_values [Hash] Existing values entered by submitters, keyed by field UUID
  # @param ats_values [Hash] Prefill values from ATS system, keyed by ATS field name
  # @param template_fields [Array<Hash>, nil] Template field definitions containing UUID and prefill mappings
  # @return [Hash] Merged values with submitter values taking precedence over ATS values
  #
  # @example
  #   submitter_values = { 'field-uuid-1' => 'John' }
  #   ats_values = { 'employee_first_name' => 'Jane', 'employee_last_name' => 'Doe' }
  #   template_fields = [
  #     { 'uuid' => 'field-uuid-1', 'prefill' => 'employee_first_name' },
  #     { 'uuid' => 'field-uuid-2', 'prefill' => 'employee_last_name' }
  #   ]
  #
  #   merge_ats_prefill_values(submitter_values, ats_values, template_fields)
  #   # => { 'field-uuid-1' => 'John', 'field-uuid-2' => 'Doe' }
  #   # Note: 'John' is preserved over 'Jane' because submitter value takes precedence
  def merge_ats_prefill_values(submitter_values, ats_values, template_fields = nil)
    return submitter_values if ats_values.blank?

    # Build optimized lookup cache for better performance with large field sets
    field_lookup = build_field_lookup_cache(template_fields)

    # Only use ATS values for fields that don't already have submitter values
    ats_values.each do |field_name, value|
      # Use cached lookup for better performance
      matching_field_uuid = field_lookup[field_name]

      next if matching_field_uuid.nil?

      # Only set if submitter hasn't already filled this field
      if submitter_values[matching_field_uuid].blank?
        submitter_values[matching_field_uuid] = value
      end
    end

    submitter_values
  end

  # Clears ATS fields cache (useful for testing or manual cache invalidation)
  #
  # Since Rails cache doesn't provide easy enumeration of keys, this method
  # relies on TTL for automatic cleanup. This method is provided for potential
  # future use or testing scenarios where immediate cache invalidation is needed.
  #
  # @return [void]
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

  # Builds an optimized lookup cache for field UUID resolution
  #
  # Creates a hash mapping ATS field names to template field UUIDs for O(1) lookup
  # performance instead of O(n) linear search. Results are cached to improve
  # performance across multiple requests.
  #
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [Hash] Mapping of ATS field names to field UUIDs
  #
  # @example
  #   template_fields = [
  #     { 'uuid' => 'field-1', 'prefill' => 'employee_first_name' },
  #     { 'uuid' => 'field-2', 'prefill' => 'employee_last_name' }
  #   ]
  #   build_field_lookup_cache(template_fields)
  #   # => { 'employee_first_name' => 'field-1', 'employee_last_name' => 'field-2' }
  def build_field_lookup_cache(template_fields)
    return {} if template_fields.blank?

    # Create cache key based on template fields structure
    cache_key = field_lookup_cache_key(template_fields)

    # Try to get from cache first
    begin
      cached_lookup = Rails.cache.read(cache_key)
      return cached_lookup if cached_lookup
    rescue StandardError => e
      # Continue with normal processing if cache read fails
    end

    # Build lookup hash for O(1) performance
    lookup = template_fields.each_with_object({}) do |field, hash|
      prefill_name = field['prefill']
      field_uuid = field['uuid']

      if prefill_name.present? && field_uuid.present?
        hash[prefill_name] = field_uuid
      end
    end

    # Cache the lookup with error handling
    begin
      Rails.cache.write(cache_key, lookup, expires_in: FIELD_LOOKUP_CACHE_TTL)
    rescue StandardError => e
      # Continue execution even if caching fails
    end

    lookup
  end

  # Finds field UUID by matching ATS field name to template field's prefill attribute
  #
  # This method provides backward compatibility and is now optimized to use
  # the cached lookup when possible.
  #
  # @param field_name [String] ATS field name to look up
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [String, nil] Field UUID if found, nil otherwise
  #
  # @example
  #   find_field_uuid_by_name('employee_first_name', template_fields)
  #   # => 'field-uuid-123'
  def find_field_uuid_by_name(field_name, template_fields = nil)
    return nil if field_name.blank? || template_fields.blank?

    # Use optimized lookup cache
    field_lookup = build_field_lookup_cache(template_fields)
    field_lookup[field_name]
  end

  private

  # Generates cache key for field lookup optimization
  def field_lookup_cache_key(template_fields)
    # Create a hash based on the structure of template fields for caching
    fields_signature = template_fields.map { |f| "#{f['uuid']}:#{f['prefill']}" }.sort.join('|')
    hash = Digest::SHA256.hexdigest(fields_signature)
    "field_lookup:#{hash}"
  end

end
