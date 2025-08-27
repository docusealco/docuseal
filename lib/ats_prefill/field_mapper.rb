# frozen_string_literal: true

module AtsPrefill
  module FieldMapper
    # Creates optimized mapping between ATS field names and template field UUIDs
    #
    # Creates a hash mapping ATS field names to template field UUIDs for O(1) lookup
    # performance instead of O(n) linear search. Results are cached to improve
    # performance across multiple requests.
    #
    # @param template_fields [Array<Hash>, nil] Template field definitions containing UUID and prefill mappings
    # @return [Hash] Mapping of ATS field names to field UUIDs
    #
    # @example
    #   template_fields = [
    #     { 'uuid' => 'field-1', 'prefill' => 'employee_first_name' },
    #     { 'uuid' => 'field-2', 'prefill' => 'employee_last_name' }
    #   ]
    #   AtsPrefill::FieldMapper.call(template_fields)
    #   # => { 'employee_first_name' => 'field-1', 'employee_last_name' => 'field-2' }
    def call(template_fields)
      return {} if template_fields.blank?

      cache_key = CacheManager.generate_cache_key('field_mapping', build_cache_signature(template_fields))

      CacheManager.fetch_field_mapping(cache_key) do
        build_field_mapping(template_fields)
      end
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
    #   find_field_uuid('employee_first_name', template_fields)
    #   # => 'field-uuid-123'
    def find_field_uuid(field_name, template_fields = nil)
      return nil if field_name.blank? || template_fields.blank?

      # Use optimized lookup cache
      field_mapping = call(template_fields)
      field_mapping[field_name]
    end

    private

    # Builds a cache signature from template fields for consistent caching
    #
    # @param template_fields [Array<Hash>] Template field definitions
    # @return [String] Cache signature based on field UUIDs and prefill attributes
    def build_cache_signature(template_fields)
      return '' if template_fields.blank?

      # Extract relevant data for cache key generation - format matches test expectations
      template_fields
        .filter_map do |field|
        "#{field['uuid']}:#{field['prefill']}" if field['uuid'].present? && field['prefill'].present?
      end
        .sort
        .join('|')
    end

    # Builds the actual field mapping hash
    #
    # @param template_fields [Array<Hash>] Template field definitions
    # @return [Hash] Mapping of ATS field names to field UUIDs
    def build_field_mapping(template_fields)
      template_fields.each_with_object({}) do |field, mapping|
        prefill_name = field['prefill']
        field_uuid = field['uuid']

        mapping[prefill_name] = field_uuid if prefill_name.present? && field_uuid.present?
      end
    end

    module_function :call, :find_field_uuid, :build_cache_signature, :build_field_mapping
  end
end
