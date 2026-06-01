module MultiXML
  # Base module for XML parser implementations
  #
  # Built-in parsers ``extend`` this module and declare the XML library's
  # native parse-error class as a ``ParseError`` constant. The inherited
  # {#parse_error} method reads that constant so {MultiXML.parse} can
  # wrap backend-specific parse failures uniformly.
  #
  # Matches the role of {MultiJSON::Adapter} — a shared contract that
  # custom parsers can pick up by extending this module, while keeping
  # backwards compatibility with parsers that instead define a
  # ``parse_error`` method directly.
  #
  # @example Writing a custom parser
  #   module MyParser
  #     extend MultiXML::Parser
  #
  #     ParseError = Class.new(StandardError)
  #
  #     def self.parse(io, namespaces: :strip)
  #       # parse io into a Hash, raising ParseError on failure
  #     end
  #   end
  #
  #   MultiXML.parser = MyParser
  #
  # @api public
  module Parser
    # Return the parse-error class declared on the including parser
    #
    # The lookup uses ``inherit: false`` so a stray top-level
    # ``::ParseError`` in the host process (Racc defines one when
    # Nokogiri is loaded) is correctly ignored.
    #
    # @api public
    # @return [Class] the ParseError class declared on ``self``
    # @raise [ParserLoadError] when ``self`` doesn't define ParseError
    # @example
    #   MultiXML::Parsers::Nokogiri.parse_error
    #   #=> Nokogiri::XML::SyntaxError
    def parse_error
      const_get(:ParseError, false)
    rescue NameError
      raise ParserLoadError, "Parser #{self} must define a ParseError constant"
    end
  end
end
