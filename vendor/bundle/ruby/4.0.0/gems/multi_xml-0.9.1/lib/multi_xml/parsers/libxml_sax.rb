require "libxml-ruby"
require "stringio"
require_relative "sax_handler"
require_relative "libxml"

module MultiXML
  module Parsers
    # SAX-based parser using LibXML (faster for large documents)
    #
    # @api private
    module LibxmlSax
      extend MultiXML::Parser

      module_function

      # Exception class raised on LibXML parse failure
      # @api private
      ParseError = ::LibXML::XML::Error

      # Parse XML from a string or IO object
      #
      # @api private
      # @param xml [String, IO] XML content
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [LibXML::XML::Error] if XML is malformed
      def parse(xml, namespaces: :strip)
        source = xml.respond_to?(:read) ? xml.read : xml.to_s
        return {} if source.empty?

        return parse_with_dom(source, namespaces) if dom_fallback?(source, namespaces)

        parse_with_sax(source, namespaces)
      end

      # Detect whether a start tag has attributes that collide after stripping
      #
      # @api private
      # @param source [String] XML source
      # @return [Boolean] true when stripped attribute locals collide
      def stripped_attribute_collision?(source)
        source.scan(%r{<(?![!?/])[^>]*>}m).any? do |tag|
          local_names = attribute_names(tag).map { |name| name.split(":", 2).last }
          local_names.uniq.length < local_names.length
        end
      end

      # Extract non-xmlns attribute names from a start tag
      #
      # @api private
      # @param tag [String] Start tag source
      # @return [Array<String>] attribute names
      def attribute_names(tag)
        tag.scan(/\s([a-zA-Z_][\w.-]*(?::[a-zA-Z_][\w.-]*)?)\s*=/).flatten.reject do |name|
          name == "xmlns" || name.start_with?("xmlns:")
        end
      end

      # Determine whether libxml_sax must fall back to the DOM parser
      #
      # @api private
      # @param source [String] XML source
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Boolean] true when DOM parsing is required
      def dom_fallback?(source, namespaces)
        namespaces != :strip || stripped_attribute_collision?(source)
      end

      # Parse via the DOM libxml backend
      #
      # @api private
      # @param source [String] XML source
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      def parse_with_dom(source, namespaces)
        Libxml.parse(StringIO.new(source), namespaces: namespaces)
      end

      # Parse via libxml-ruby's SAX parser
      #
      # @api private
      # @param source [String] XML source
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      def parse_with_sax(source, namespaces)
        LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)
        handler = Handler.new(namespaces)
        parser = ::LibXML::XML::SaxParser.io(StringIO.new(source))
        parser.callbacks = handler
        parser.parse
        handler.result
      end

      # LibXML SAX handler.
      #
      # libxml-ruby's namespace-aware callback strips prefixes from the attrs
      # hash, so we rely on the qname-preserving `on_start_element` callback
      # and resolve namespaces via SaxHandler's scope stack.
      #
      # @api private
      class Handler
        include ::LibXML::XML::SaxParser::Callbacks
        include SaxHandler

        # Create a new SAX handler
        #
        # @api private
        # @param mode [Symbol] Namespace handling mode
        # @return [Handler] new handler instance
        def initialize(mode)
          initialize_handler(mode)
        end

        # Handle start of document (no-op)
        #
        # @api private
        # @return [void]
        def on_start_document
        end

        # Handle end of document (no-op)
        #
        # @api private
        # @return [void]
        def on_end_document
        end

        # Handle parse errors (no-op; libxml-ruby raises directly)
        #
        # @api private
        # @param _error [String] Error message (unused)
        # @return [void]
        def on_error(_error)
        end

        # Handle start of an element
        #
        # libxml-ruby strips xmlns declarations from attrs and passes through
        # prefixed names for regular attributes. Since libxml_sax only uses
        # this handler in :strip mode, we route through the namespace-aware
        # entrypoint with empty ns_decls and treat attribute qnames as-if
        # they had no namespace — matching the desired :strip output.
        #
        # @api private
        # @param name [String] Element name (possibly prefixed)
        # @param attrs [Hash] Attributes as name => value
        # @return [void]
        def on_start_element(name, attrs = {})
          prefix, local = sax_split_qname(name.to_s)
          tuples = attrs.map do |k, v|
            ap, al = sax_split_qname(k.to_s)
            [ap, al, v]
          end
          handle_start_element_ns(local, prefix, tuples, [])
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def on_end_element(_name)
          handle_end_element
        end

        private

        # Split a prefixed name into [prefix, local]
        #
        # @api private
        # @param name [String] Prefixed or local name
        # @return [Array<String, nil>] prefix and local name
        def sax_split_qname(name)
          p, l = name.split(":", 2)
          l ? [p, l] : [nil, p]
        end

        # Handle character data (also aliased as `on_cdata_block`)
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def on_characters(text) = append_text(text)
        alias_method :on_cdata_block, :on_characters
      end
    end
  end
end
