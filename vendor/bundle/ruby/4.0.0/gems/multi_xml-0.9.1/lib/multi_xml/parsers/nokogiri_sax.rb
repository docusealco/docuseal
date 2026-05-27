require "nokogiri"
require "stringio"
require_relative "sax_handler"

module MultiXML
  module Parsers
    # SAX-based parser using Nokogiri (faster for large documents)
    #
    # @api private
    module NokogiriSax
      extend MultiXML::Parser

      module_function

      # Exception class raised on Nokogiri parse failure
      # @api private
      ParseError = ::Nokogiri::XML::SyntaxError

      # Parse XML from a string or IO object
      #
      # @api private
      # @param xml [String, IO] XML content
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [Nokogiri::XML::SyntaxError] if XML is malformed
      def parse(xml, namespaces: :strip)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        handler = Handler.new(namespaces)
        ::Nokogiri::XML::SAX::Parser.new(handler).parse(io)
        handler.result
      end

      # Nokogiri SAX handler.
      #
      # Nokogiri always invokes `start_element_namespace` (even for documents
      # without namespaces — prefix/uri come through as nil). We don't define
      # `start_element` because it would never fire.
      #
      # @api private
      class Handler < ::Nokogiri::XML::SAX::Document
        include SaxHandler

        # Create a new SAX handler
        #
        # @api private
        # @param mode [Symbol] Namespace handling mode
        # @return [Handler] new handler instance
        def initialize(mode)
          super()
          initialize_handler(mode)
        end

        # Handle start of document (no-op)
        #
        # @api private
        # @return [void]
        def start_document
        end

        # Handle end of document (no-op)
        #
        # @api private
        # @return [void]
        def end_document
        end

        # Handle parse errors
        #
        # @api private
        # @param message [String] Error message
        # @return [void]
        # @raise [Nokogiri::XML::SyntaxError] always
        def error(message)
          raise ::Nokogiri::XML::SyntaxError, message
        end

        # Handle start of a namespaced element
        #
        # Signature is fixed by the Nokogiri SAX protocol.
        #
        # @api private
        # @param local [String] Local element name
        # @param attrs [Array<Nokogiri::XML::SAX::Parser::Attribute>] Attributes
        # @param prefix [String, nil] Element namespace prefix
        # @param _uri [String, nil] Element namespace URI (unused)
        # @param ns [Array] Namespace declarations as [prefix, uri] pairs
        # @return [void]
        # rubocop:disable Metrics/ParameterLists, Naming/MethodParameterName
        def start_element_namespace(local, attrs = [], prefix = nil, _uri = nil, ns = [])
          ns_decls = ns.map { |p, u| [normalize(p), u] }
          attr_tuples = attrs.map { |a| [normalize(a.prefix), a.localname, a.value] }
          handle_start_element_ns(local, normalize(prefix), attr_tuples, ns_decls)
        end
        # rubocop:enable Metrics/ParameterLists, Naming/MethodParameterName

        # Handle end of a namespaced element
        #
        # @api private
        # @param _local [String] Local element name (unused)
        # @param _prefix [String, nil] Namespace prefix (unused)
        # @param _uri [String, nil] Namespace URI (unused)
        # @return [void]
        def end_element_namespace(_local, _prefix = nil, _uri = nil)
          handle_end_element
        end

        # Handle character data
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def characters(text) = append_text(text)
        alias_method :cdata_block, :characters

        private

        # Normalize a value, returning nil for empty or nil input
        #
        # @api private
        # @param value [String, nil] Value to normalize
        # @return [String, nil] value or nil if empty
        def normalize(value)
          (value.nil? || value.to_s.empty?) ? nil : value
        end
      end
    end
  end
end
