module MultiJson
  # Raised when JSON parsing fails
  #
  # Wraps the underlying adapter's parse error with the original input data.
  #
  # @api public
  class ParseError < StandardError
    # The input string that failed to parse
    #
    # @api public
    # @return [String, nil] the original input data
    # @example
    #   error.data  #=> "{invalid json}"
    attr_reader :data

    # Create a new ParseError
    #
    # @api public
    # @param message [String, nil] error message
    # @param data [String, nil] the input that failed to parse
    # @param cause [Exception, nil] the original exception
    # @return [ParseError] new error instance
    # @example
    #   ParseError.new("unexpected token", data: "{invalid}", cause: err)
    def initialize(message = nil, data: nil, cause: nil)
      super(message)
      @data = data
      set_backtrace(cause.backtrace) if cause
    end

    # Build a ParseError from an original exception
    #
    # @api public
    # @param original_exception [Exception] the adapter's parse error
    # @param data [String] the input that failed to parse
    # @return [ParseError] new error with formatted message
    # @example
    #   ParseError.build(JSON::ParserError.new("..."), "{bad json}")
    def self.build(original_exception, data)
      new(original_exception.message, data: data, cause: original_exception)
    end
  end

  # Legacy aliases for backward compatibility
  DecodeError = LoadError = ParseError
end
