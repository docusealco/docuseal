module MultiXML
  # Internal helpers for resolving and loading parser backends
  #
  # @api private
  module ParserResolution
    private

    # Resolve a parser specification to a module
    #
    # @api private
    # @param spec [Symbol, String, Class, Module] Parser specification
    # @return [Module] Resolved parser module
    # @raise [ParserLoadError] if spec is invalid, the parser file
    #   can't be required, or the resolved parser doesn't satisfy
    #   the parser contract
    def resolve_parser(spec)
      parser = case spec
      when String, Symbol then load_parser(spec)
      when Module then spec
      else raise ParserLoadError, "expected parser to be a Symbol, String, or Module, got #{spec.inspect}"
      end
      validate_parser!(parser)
    rescue ::LoadError => e
      raise ParserLoadError.build(e)
    end

    # Load a parser by name
    #
    # @api private
    # @param name [Symbol, String] Parser name
    # @return [Module] Loaded parser module
    def load_parser(name)
      name = name.to_s.downcase
      require "multi_xml/parsers/#{name}"
      Parsers.const_get(camelize(name))
    end

    # Validate that a parser satisfies the documented contract
    #
    # Custom parsers are accepted as modules/classes, so fail fast
    # during parser resolution rather than later on the first parse
    # call. A parser must respond to ``.parse`` and must either
    # define a ``ParseError`` constant or respond to ``.parse_error``.
    #
    # @api private
    # @param parser [Module] parser class or module
    # @return [Module] the validated parser
    # @raise [ParserLoadError] when the parser is missing a required method
    def validate_parser!(parser)
      raise ParserLoadError, "Parser #{parser} must respond to .parse" unless parser.respond_to?(:parse)
      unless parser.const_defined?(:ParseError, false) || parser.respond_to?(:parse_error)
        raise ParserLoadError, "Parser #{parser} must define a ParseError constant or a .parse_error method"
      end

      parser
    end

    # Convert underscored string to CamelCase
    #
    # @api private
    # @param name [String] Underscored string
    # @return [String] CamelCased string
    def camelize(name)
      name.split("_").map(&:capitalize).join
    end

    # Detect the best available parser
    #
    # @api private
    # @return [Symbol] Parser name
    # @raise [NoParserError] if no parser is available
    def detect_parser
      find_loaded_parser || find_available_parser || raise_no_parser_error
    end

    # Parser constant names mapped to their symbols, in preference order
    #
    # @api private
    LOADED_PARSER_CHECKS = {
      Ox: :ox,
      LibXML: :libxml,
      Nokogiri: :nokogiri,
      Oga: :oga
    }.freeze
    private_constant :LOADED_PARSER_CHECKS

    # Find an already-loaded parser library
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none loaded
    def find_loaded_parser
      LOADED_PARSER_CHECKS.each do |const_name, parser_name|
        next if skip_on_platform?(parser_name)
        return parser_name if Object.const_defined?(const_name)
      end
      nil
    end

    # Try to load and find an available parser
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none available
    def find_available_parser
      PARSER_PREFERENCE.each do |library, parser_name|
        next if skip_on_platform?(parser_name)
        return parser_name if try_require(library)
      end
      nil
    end

    # Whether a parser should be skipped during auto-detection
    #
    # Ox loads on TruffleRuby but its SAX callbacks misbehave under the
    # native interpreter, so type-attributed XML parses to an empty hash
    # and the disallowed-type check is silently bypassed. Skip it during
    # auto-detection so MultiXML falls through to a working backend.
    # Callers that pass ``parser: :ox`` explicitly still get Ox.
    #
    # @api private
    # @param parser_name [Symbol] parser symbol from preference list
    # @return [Boolean] true when this parser must be skipped
    def skip_on_platform?(parser_name)
      parser_name == :ox && RUBY_ENGINE == "truffleruby"
    end

    # Attempt to require a library
    #
    # @api private
    # @param library [String] Library to require
    # @return [Boolean] true if successful, false if LoadError
    def try_require(library)
      require library
      true
    rescue LoadError
      false
    end

    # Raise an error indicating no parser is available
    #
    # @api private
    # @return [void]
    # @raise [NoParserError] always
    def raise_no_parser_error
      raise NoParserError, <<~MSG.chomp
        No XML parser detected. Install one of: ox, nokogiri, libxml-ruby, or oga.
        See https://github.com/sferik/multi_xml for more information.
      MSG
    end
  end
end
