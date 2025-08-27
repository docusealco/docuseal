# frozen_string_literal: true

module PrefillFieldsHelper
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
    AtsPrefill.extract_fields(params)
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
    AtsPrefill.merge_values(submitter_values, ats_values, template_fields)
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
    AtsPrefill.find_field_uuid(field_name, template_fields)
  end

  # Clears ATS fields cache (useful for testing or manual cache invalidation)
  #
  # Since Rails cache doesn't provide easy enumeration of keys, this method
  # relies on TTL for automatic cleanup. This method is provided for potential
  # future use or testing scenarios where immediate cache invalidation is needed.
  #
  # @return [void]
  def clear_ats_fields_cache
    AtsPrefill.clear_cache
  end

  # Legacy method aliases for backward compatibility
  alias build_field_lookup_cache merge_ats_prefill_values

  private

  # Legacy private methods maintained for any potential direct usage
  # These now delegate to the service layer for consistency

  def read_from_cache(cache_key)
    AtsPrefill::CacheManager.read_from_cache(cache_key)
  end

  def parse_ats_fields_param(ats_fields_param)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    AtsPrefill::FieldExtractor.send(:parse_encoded_fields, ats_fields_param)
  end

  def validate_and_filter_field_names(field_names)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    AtsPrefill::FieldExtractor.send(:validate_field_names, field_names)
  end

  def valid_ats_field_name?(name)
    # This is now handled internally by FieldExtractor
    # Kept for backward compatibility but not recommended for direct use
    AtsPrefill::FieldExtractor.send(:valid_ats_field_name?, name)
  end

  def ats_fields_cache_key(ats_fields_param)
    AtsPrefill::CacheManager.generate_cache_key('ats_fields', ats_fields_param)
  end

  def cache_result(cache_key, value, ttl)
    AtsPrefill::CacheManager.write_to_cache(cache_key, value, ttl)
  end

  def cache_and_return_empty(cache_key)
    cache_result(cache_key, [], 300) # 5 minutes
    []
  end

  def field_lookup_cache_key(template_fields)
    signature = AtsPrefill::FieldMapper.send(:build_cache_signature, template_fields)
    AtsPrefill::CacheManager.generate_cache_key('field_mapping', signature)
  end
end
