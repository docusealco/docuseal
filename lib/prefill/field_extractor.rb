# frozen_string_literal: true

module Prefill
  module FieldExtractor
    # Valid field name pattern for security validation
    VALID_FIELD_PATTERN = /\A(employee|manager|account|location)_[a-z]+(?:_[a-z]+)*\z/

    # Extracts and validates prefill field names from Base64-encoded parameters
    #
    # This method decodes the prefill_fields parameter, validates the field names against
    # allowed patterns, and caches the results to improve performance on repeated requests.
    #
    # @param params [ActionController::Parameters] Request parameters
    # @return [Array<String>] Array of valid prefill field names, empty array if none found or on error
    #
    # @example
    #   # With params[:prefill_fields] = Base64.urlsafe_encode64(['employee_first_name', 'employee_email'].to_json)
    #   Prefill::FieldExtractor.call(params)
    #   # => ['employee_first_name', 'employee_email']
    def call(params)
      return [] if params[:prefill_fields].blank?

      cache_key = CacheManager.generate_cache_key('prefill_fields', params[:prefill_fields])

      CacheManager.fetch_field_extraction(cache_key) do
        extract_and_validate_fields(params[:prefill_fields])
      end
    end

    # Extracts and validates field names from encoded parameter
    #
    # @param encoded_param [String] Base64-encoded JSON string containing field names
    # @return [Array<String>] Array of valid field names
    def extract_and_validate_fields(encoded_param)
      field_names = parse_encoded_fields(encoded_param)
      return [] if field_names.nil?

      validate_field_names(field_names)
    end

    # Parses and decodes the prefill fields parameter
    #
    # @param encoded_param [String] Base64-encoded JSON string containing field names
    # @return [Array<String>, nil] Array of field names if parsing succeeds, nil on error
    def parse_encoded_fields(encoded_param)
      decoded_json = Base64.urlsafe_decode64(encoded_param)
      JSON.parse(decoded_json)
    rescue StandardError
      # Return nil if Base64 decoding or JSON parsing fails
      nil
    end

    # Validates and filters field names to only include allowed patterns
    #
    # @param field_names [Array] Array of field names to validate
    # @return [Array<String>] Array of valid field names, empty array if input is invalid
    def validate_field_names(field_names)
      # Validate that we got an array of strings
      return [] unless field_names.is_a?(Array) && field_names.all?(String)

      # Filter to only expected field name patterns
      field_names.select { |name| valid_prefill_field_name?(name) }
    end

    # Checks if a field name matches the valid prefill field pattern
    #
    # @param name [String] Field name to validate
    # @return [Boolean] True if field name is valid, false otherwise
    def valid_prefill_field_name?(name)
      # Only allow expected field name patterns (security)
      name.match?(VALID_FIELD_PATTERN)
    end

    module_function :call, :extract_and_validate_fields, :parse_encoded_fields, :validate_field_names,
                    :valid_prefill_field_name?
  end
end
