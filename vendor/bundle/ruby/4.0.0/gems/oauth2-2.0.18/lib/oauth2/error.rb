# frozen_string_literal: true

module OAuth2
  # Represents an OAuth2 error condition.
  #
  # Wraps details from an OAuth2::Response or Hash payload returned by an
  # authorization server, exposing error code and description per RFC 6749.
  class Error < StandardError
    # @return [OAuth2::Response, Hash, Object] Original response or payload used to build the error
    # @return [String] Raw body content (if available)
    # @return [String, nil] Error code (e.g., 'invalid_grant')
    # @return [String, nil] Human-readable description for the error
    attr_reader :response, :body, :code, :description

    # Create a new OAuth2::Error
    #
    # @param [OAuth2::Response, Hash, Object] response A Response or error payload
    def initialize(response)
      @response = response
      if response.respond_to?(:parsed)
        if response.parsed.is_a?(Hash)
          @code = response.parsed["error"]
          @description = response.parsed["error_description"]
        end
      elsif response.is_a?(Hash)
        @code = response["error"]
        @description = response["error_description"]
      end
      @body = if response.respond_to?(:body)
        response.body
      else
        @response
      end
      message_opts = parse_error_description(@code, @description)
      super(error_message(@body, message_opts))
    end

  private

    # Builds a multi-line error message including description and raw body.
    #
    # @param [String, #encode] response_body Response body content
    # @param [Hash] opts Options including :error_description
    # @return [String] Message suitable for StandardError
    def error_message(response_body, opts = {})
      lines = []

      lines << opts[:error_description] if opts[:error_description]

      error_string = if response_body.respond_to?(:encode) && opts[:error_description].respond_to?(:encoding)
        script_encoding = opts[:error_description].encoding
        response_body.encode(script_encoding, invalid: :replace, undef: :replace)
      else
        response_body
      end

      lines << error_string

      lines.join("\n")
    end

    # Formats the OAuth2 error code and description into a single string.
    #
    # @param [String, nil] code OAuth2 error code
    # @param [String, nil] description OAuth2 error description
    # @return [Hash] Options hash containing :error_description when present
    def parse_error_description(code, description)
      return {} unless code || description

      error_description = ""
      error_description += "#{code}: " if code
      error_description += description if description

      {error_description: error_description}
    end
  end
end
