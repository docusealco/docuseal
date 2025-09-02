# frozen_string_literal: true

module Prefill
  module ValueMerger
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
    #   Prefill::ValueMerger.call(submitter_values, prefill_values, template_fields)
    #   # => { 'field-uuid-1' => 'John', 'field-uuid-2' => 'Doe' }
    #   # Note: 'John' is preserved over 'Jane' because submitter value takes precedence
    def call(submitter_values, prefill_values, template_fields = nil)
      return submitter_values if prefill_values.blank?

      # Build optimized lookup cache for better performance with large field sets
      field_mapping = FieldMapper.call(template_fields)

      merge_values(submitter_values, prefill_values, field_mapping)
    end

    private

    # Merges prefill values into submitter values for fields that are blank
    #
    # @param submitter_values [Hash] Current submitter field values
    # @param prefill_values [Hash] Prefill field values to merge
    # @param field_mapping [Hash] Mapping of prefill field names to template field UUIDs
    # @return [Hash] Updated submitter values
    def merge_values(submitter_values, prefill_values, field_mapping)
      return submitter_values if prefill_values.blank? || field_mapping.blank?

      prefill_values.each do |prefill_field_name, prefill_value|
        field_uuid = field_mapping[prefill_field_name]
        next unless field_uuid

        # Only merge if the submitter value is blank (nil or empty string)
        # Note: false and 0 are valid values that should not be overwritten
        current_value = submitter_values[field_uuid]
        submitter_values[field_uuid] = prefill_value if current_value.nil? || current_value == ''
      end

      submitter_values
    end

    module_function :call, :merge_values
  end
end
