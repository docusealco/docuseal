# frozen_string_literal: true

module AtsPrefill
  module ValueMerger
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
    #   AtsPrefill::ValueMerger.call(submitter_values, ats_values, template_fields)
    #   # => { 'field-uuid-1' => 'John', 'field-uuid-2' => 'Doe' }
    #   # Note: 'John' is preserved over 'Jane' because submitter value takes precedence
    def call(submitter_values, ats_values, template_fields = nil)
      return submitter_values if ats_values.blank?

      # Build optimized lookup cache for better performance with large field sets
      field_mapping = FieldMapper.call(template_fields)

      merge_values(submitter_values, ats_values, field_mapping)
    end

    private

    # Merges ATS values into submitter values for fields that are blank
    #
    # @param submitter_values [Hash] Current submitter field values
    # @param ats_values [Hash] ATS field values to merge
    # @param field_mapping [Hash] Mapping of ATS field names to template field UUIDs
    # @return [Hash] Updated submitter values
    def merge_values(submitter_values, ats_values, field_mapping)
      return submitter_values if ats_values.blank? || field_mapping.blank?

      ats_values.each do |ats_field_name, ats_value|
        field_uuid = field_mapping[ats_field_name]
        next unless field_uuid

        # Only merge if the submitter value is blank (nil or empty string)
        # Note: false and 0 are valid values that should not be overwritten
        current_value = submitter_values[field_uuid]
        submitter_values[field_uuid] = ats_value if current_value.nil? || current_value == ''
      end

      submitter_values
    end

    module_function :call, :merge_values
  end
end
