# frozen_string_literal: true

require_relative 'ats_prefill/cache_manager'
require_relative 'ats_prefill/field_extractor'
require_relative 'ats_prefill/field_mapper'
require_relative 'ats_prefill/value_merger'

# AtsPrefill provides a clean facade for ATS (Applicant Tracking System) prefill functionality.
# This module encapsulates the complexity of extracting, validating, mapping, and merging
# ATS field values with existing submitter data.
#
# The module follows the service object pattern established in DocuSeal's codebase,
# providing focused, testable, and reusable components for ATS integration.
#
# @example Basic usage
#   # Extract valid field names from request parameters
#   field_names = AtsPrefill.extract_fields(params)
#
#   # Merge ATS values with existing submitter values
#   merged_values = AtsPrefill.merge_values(submitter_values, ats_values, template_fields)
#
#   # Find specific field UUID by name
#   field_uuid = AtsPrefill.find_field_uuid('employee_first_name', template_fields)
module AtsPrefill
  # Extracts and validates ATS field names from request parameters
  #
  # @param params [ActionController::Parameters] Request parameters containing ats_fields
  # @return [Array<String>] Array of valid ATS field names
  #
  # @example
  #   AtsPrefill.extract_fields(params)
  #   # => ['employee_first_name', 'employee_email']
  def extract_fields(params)
    FieldExtractor.call(params)
  end

  # Merges ATS prefill values with existing submitter values
  #
  # Existing submitter values always take precedence over ATS values to prevent
  # overwriting user input.
  #
  # @param submitter_values [Hash] Existing values entered by submitters
  # @param ats_values [Hash] Prefill values from ATS system
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [Hash] Merged values with submitter values taking precedence
  #
  # @example
  #   AtsPrefill.merge_values(
  #     { 'field-1' => 'John' },
  #     { 'employee_first_name' => 'Jane', 'employee_last_name' => 'Doe' },
  #     template_fields
  #   )
  #   # => { 'field-1' => 'John', 'field-2' => 'Doe' }
  def merge_values(submitter_values, ats_values, template_fields = nil)
    ValueMerger.call(submitter_values, ats_values, template_fields)
  end

  # Finds field UUID by matching ATS field name to template field's prefill attribute
  #
  # @param field_name [String] ATS field name to look up
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [String, nil] Field UUID if found, nil otherwise
  #
  # @example
  #   AtsPrefill.find_field_uuid('employee_first_name', template_fields)
  #   # => 'field-uuid-123'
  def find_field_uuid(field_name, template_fields)
    FieldMapper.find_field_uuid(field_name, template_fields)
  end

  # Creates field mapping for direct access to the mapping hash
  #
  # @param template_fields [Array<Hash>, nil] Template field definitions
  # @return [Hash] Mapping of ATS field names to field UUIDs
  #
  # @example
  #   AtsPrefill.build_field_mapping(template_fields)
  #   # => { 'employee_first_name' => 'field-1', 'employee_last_name' => 'field-2' }
  def build_field_mapping(template_fields)
    FieldMapper.call(template_fields)
  end

  # Clears ATS-related caches (useful for testing or manual cache invalidation)
  #
  # Since Rails cache doesn't provide easy enumeration of keys, this method
  # relies on TTL for automatic cleanup. This method is provided for potential
  # future use or testing scenarios where immediate cache invalidation is needed.
  #
  # @return [void]
  def clear_cache
    # Since we can't easily enumerate cache keys, we'll rely on TTL for cleanup
    # This method is provided for potential future use or testing
  end

  module_function :extract_fields, :merge_values, :find_field_uuid, :build_field_mapping, :clear_cache
end
