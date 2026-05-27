module MultiXML
  # Raised when XML parsing fails
  #
  # Preserves the original XML and underlying cause for debugging.
  #
  # @api public
  # @example Catching a parse error
  #   begin
  #     MultiXML.parse('<invalid>')
  #   rescue MultiXML::ParseError => e
  #     puts e.xml   # The malformed XML
  #     puts e.cause # The underlying parser exception
  #   end
  class ParseError < StandardError
    # The original XML that failed to parse
    #
    # @api public
    # @return [String, nil] the XML string that caused the error
    # @example Access the failing XML
    #   error.xml #=> "<invalid>"
    attr_reader :xml

    # The underlying parser exception
    #
    # @api public
    # @return [Exception, nil] the original exception from the parser
    # @example Access the cause
    #   error.cause #=> #<Nokogiri::XML::SyntaxError: ...>
    attr_reader :cause

    # Create a new ParseError
    #
    # @api public
    # @param message [String, nil] Error message
    # @param xml [String, nil] The original XML that failed to parse
    # @param cause [Exception, nil] The underlying parser exception
    # @return [ParseError] the new error instance
    # @example Create a parse error
    #   ParseError.new("Invalid XML", xml: "<bad>", cause: original_error)
    def initialize(message = nil, xml: nil, cause: nil)
      @xml = xml
      @cause = cause
      super(message)
    end
  end

  # Raised when no XML parser library is available
  #
  # This error is raised when MultiXML cannot find any supported XML parser.
  # Install one of: ox, nokogiri, libxml-ruby, or oga.
  #
  # @api public
  # @example Catching the error
  #   begin
  #     MultiXML.parse('<root/>')
  #   rescue MultiXML::NoParserError => e
  #     puts "Please install an XML parser gem"
  #   end
  class NoParserError < StandardError; end

  # Raised when a parser cannot be loaded or is not recognized
  #
  # Covers three failure modes in one typed error, so callers can catch
  # all "I couldn't even get to parsing" problems with one rescue:
  #   - Invalid spec type (not a Symbol, String, or Module)
  #   - LoadError from requiring the parser file
  #   - A custom parser that doesn't satisfy the contract
  #     (no .parse method or no parse_error method / ParseError constant)
  #
  # Matches the role of {MultiJSON::AdapterError}.
  #
  # @api public
  # @example Catching a load error
  #   begin
  #     MultiXML.parser = :bogus
  #   rescue MultiXML::ParserLoadError => e
  #     puts e.message
  #   end
  class ParserLoadError < ArgumentError
    # Create a new ParserLoadError
    #
    # @api public
    # @param message [String, nil] error message
    # @param cause [Exception, nil] the original exception
    # @return [ParserLoadError] new error instance
    # @example
    #   ParserLoadError.new("Unknown parser", cause: original_error)
    def initialize(message = nil, cause: nil)
      super(message)
      set_backtrace(cause.backtrace) if cause
    end

    # Build a ParserLoadError from an original exception
    #
    # The original exception's class name is included in the message so
    # a downstream consumer reading just the ParserLoadError can tell
    # whether the underlying failure was a ``LoadError``, an
    # ``ArgumentError`` from the spec validator, or some other class
    # without having to look at ``error.cause`` separately.
    #
    # @api public
    # @param original_exception [Exception] the original load error
    # @return [ParserLoadError] new error with formatted message
    # @example
    #   ParserLoadError.build(LoadError.new("cannot load such file"))
    def self.build(original_exception)
      new(
        "Did not recognize your parser specification " \
        "(#{original_exception.class}: #{original_exception.message}).",
        cause: original_exception
      )
    end
  end

  # Raised when an XML type attribute is in the disallowed list
  #
  # By default, 'yaml' and 'symbol' types are disallowed for security reasons.
  #
  # @api public
  # @example Catching a disallowed type error
  #   begin
  #     MultiXML.parse('<data type="yaml">--- :key</data>')
  #   rescue MultiXML::DisallowedTypeError => e
  #     puts e.type #=> "yaml"
  #   end
  class DisallowedTypeError < StandardError
    # The disallowed type that was encountered
    #
    # @api public
    # @return [String] the type attribute value that was disallowed
    # @example Access the disallowed type
    #   error.type #=> "yaml"
    attr_reader :type

    # Create a new DisallowedTypeError
    #
    # @api public
    # @param type [String] The disallowed type attribute value
    # @return [DisallowedTypeError] the new error instance
    # @example Create a disallowed type error
    #   DisallowedTypeError.new("yaml")
    def initialize(type)
      @type = type
      super("Disallowed type attribute: #{type.inspect}")
    end
  end
end
