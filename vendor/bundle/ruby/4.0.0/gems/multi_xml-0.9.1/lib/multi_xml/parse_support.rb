module MultiXML
  # Internal helpers for parsing and post-processing XML
  #
  # @api private
  module ParseSupport
    private

    # Normalize input to an IO-like object
    #
    # @api private
    # @param xml [String, IO] Input to normalize
    # @return [IO] IO-like object
    def normalize_input(xml)
      return xml if xml.respond_to?(:read)

      StringIO.new(xml.to_s.strip)
    end

    # Parse XML with error handling and key normalization
    #
    # @api private
    # @param io [IO] IO-like object containing XML
    # @param original_input [String, IO] Original input for error reporting
    # @param xml_parser [Module] Parser to use
    # @param namespaces [Symbol] Namespace handling mode
    # @return [Hash] Parsed XML (undasherized only when mode is :strip)
    # @raise [ParseError] if XML is malformed
    def parse_with_error_handling(io, original_input, xml_parser, namespaces)
      result = parse_with_namespaces_compatibility(io, xml_parser, namespaces) || {}
      (namespaces == :strip) ? undasherize_keys(result) : result
    rescue xml_parser.parse_error => e
      xml_string = extract_xml_for_error(original_input)
      raise(ParseError.new(e, xml: xml_string, cause: e))
    end

    # Call the parser while preserving legacy custom parser compatibility
    #
    # @api private
    # @param io [IO] IO-like object containing XML
    # @param xml_parser [Module] Parser to use
    # @param namespaces [Symbol] Namespace handling mode
    # @return [Hash, nil] Parsed XML result
    def parse_with_namespaces_compatibility(io, xml_parser, namespaces)
      if parser_supports_namespaces_keyword?(xml_parser)
        xml_parser.parse(io, namespaces: namespaces)
      else
        xml_parser.parse(io)
      end
    end

    # Validate the :namespaces mode option
    #
    # @api private
    # @param mode [Symbol] Namespace handling mode to validate
    # @return [Symbol] the validated mode
    # @raise [ArgumentError] if mode is not a recognized value
    def validate_namespaces_mode(mode)
      return mode if NAMESPACE_MODES.include?(mode)

      expected_modes = "[#{NAMESPACE_MODES.map(&:inspect).join(", ")}]"
      raise ArgumentError, "invalid :namespaces mode #{mode.inspect}; expected one of #{expected_modes}"
    end

    # Pick the parser to use for this call, honoring the :parser option
    #
    # @api private
    # @param options [Hash] Parsing options
    # @return [Module] Resolved parser module
    def resolve_parse_parser(options)
      options[:parser] ? resolve_parser(options.fetch(:parser)) : parser
    end

    # Check whether the parser accepts a `namespaces:` keyword
    #
    # @api private
    # @param xml_parser [Module] Parser to inspect
    # @return [Boolean] true when the parser accepts `namespaces:`
    def parser_supports_namespaces_keyword?(xml_parser)
      xml_parser.public_method(:parse).parameters.any? do |kind, name|
        kind == :keyrest || (name == :namespaces && %i[key keyreq].include?(kind))
      end
    end

    # Extract the original XML for ParseError reporting
    #
    # Some parser backends mutate or close IO objects on error. JRuby's
    # Nokogiri path closes StringIO instances, so prefer rewind/read when
    # available but fall back to the underlying string buffer when present.
    #
    # @api private
    # @param original_input [String, IO] original parse input
    # @return [String] XML payload for ParseError context
    def extract_xml_for_error(original_input)
      return original_input.to_s unless original_input.respond_to?(:read)

      original_input.tap(&:rewind).read
    rescue IOError
      original_input.respond_to?(:string) ? original_input.string : original_input.to_s
    end

    # Apply typecasting and key-symbolization as configured
    #
    # @api private
    # @param result [Hash] Parsed hash
    # @param options [Hash] Parsing options
    # @return [Hash] Post-processed hash
    def apply_postprocessing(result, options)
      result = typecast_xml_value(result, options.fetch(:disallowed_types)) if options.fetch(:typecast_xml_value)
      result = symbolize_keys(result) if options.fetch(:symbolize_names)
      result
    end
  end
end
