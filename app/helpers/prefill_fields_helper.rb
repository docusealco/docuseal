# frozen_string_literal: true

module PrefillFieldsHelper
  # Extracts and validates prefill field names from Base64-encoded parameters
  #
  # This method decodes the prefill_fields parameter, validates the field names against
  # allowed patterns, and caches the results to improve performance on repeated requests.
  #
  # @return [Array<String>] Array of valid prefill field names, empty array if none found or on error
  #
  # @example
  #   # With params[:prefill_fields] = Base64.urlsafe_encode64(['employee_first_name', 'employee_email'].to_json)
  #   extract_prefill_fields
  #   # => ['employee_first_name', 'employee_email']
  def extract_prefill_fields
    Prefill.extract_fields(params)
  end

  # Merges prefill values with existing submitter values
  #
  # This method combines externally-provided prefill values with values already entered by submitters.
  # Existing submitter values always take precedence over prefill values to prevent overwriting
  # user input. Uses optimized field lookup caching for better performance.
  #
  # @param submitter_values [Hash] Existing values entered by submitters, keyed by field UUID
  # @param prefill_values [Hash] Prefill values from external system, keyed by prefill field name
  # @param template_fields [Array<Hash>, nil] Template field definitions containing UUID and prefill mappings
  # @return [Hash] Merged values with submitter values taking precedence over prefill values
  #
  # @example
  #   submitter_values = { 'field-uuid-1' => 'John' }
  #   prefill_values = { 'employee_first_name' => 'Jane', 'employee_last_name' => 'Doe' }
  #   template_fields = [
  #     { 'uuid' => 'field-uuid-1', 'prefill' => 'employee_first_name' },
  #     { 'uuid' => 'field-uuid-2', 'prefill' => 'employee_last_name' }
  #   ]
  #
  #   merge_prefill_values(submitter_values, prefill_values, template_fields)
  #   # => { 'field-uuid-1' => 'John', 'field-uuid-2' => 'Doe' }
  #   # Note: 'John' is preserved over 'Jane' because submitter value takes precedence
  def merge_prefill_values(submitter_values, prefill_values, template_fields = nil)
    Prefill.merge_values(submitter_values, prefill_values, template_fields)
  end

  # Finds field UUID by matching prefill field name to template field's prefill attribute
  #
  # This method provides backward compatibility and is now optimized to use
  # the cached lookup when possible.
  #
  # @param field_name [String] Prefill field name to look up
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [String, nil] Field UUID if found, nil otherwise
  #
  # @example
  #   find_field_uuid_by_name('employee_first_name', template_fields)
  #   # => 'field-uuid-123'
  def find_field_uuid_by_name(field_name, template_fields = nil)
    Prefill.find_field_uuid(field_name, template_fields)
  end

  # Clears prefill fields cache (useful for testing or manual cache invalidation)
  #
  # Since Rails cache doesn't provide easy enumeration of keys, this method
  # relies on TTL for automatic cleanup. This method is provided for potential
  # future use or testing scenarios where immediate cache invalidation is needed.
  #
  # @return [void]
  def clear_prefill_fields_cache
    Prefill.clear_cache
  end

  # Legacy method aliases for backward compatibility
  alias build_field_lookup_cache merge_prefill_values

  private

  # Legacy private methods maintained for any potential direct usage
  # These now delegate to the service layer for consistency

  def read_from_cache(cache_key)
    Prefill::CacheManager.read_from_cache(cache_key)
  end

  def parse_prefill_fields_param(prefill_fields_param)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    Prefill::FieldExtractor.send(:parse_encoded_fields, prefill_fields_param)
  end

  def validate_and_filter_field_names(field_names)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    Prefill::FieldExtractor.send(:validate_field_names, field_names)
  end

  def valid_prefill_field_name?(name)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    Prefill::FieldExtractor.send(:valid_prefill_field_name?, name)
  end

  def prefill_fields_cache_key(prefill_fields_param)
    Prefill::CacheManager.generate_cache_key('prefill_fields', prefill_fields_param)
  end

  def cache_result(cache_key, value, ttl)
    Prefill::CacheManager.write_to_cache(cache_key, value, ttl)
  end

  def cache_and_return_empty(cache_key)
    cache_result(cache_key, [], 300) # 5 minutes
    []
  end

  def field_lookup_cache_key(template_fields)
    signature = Prefill::FieldMapper.send(:build_cache_signature, template_fields)
    Prefill::CacheManager.generate_cache_key('field_mapping', signature)
  end
end
