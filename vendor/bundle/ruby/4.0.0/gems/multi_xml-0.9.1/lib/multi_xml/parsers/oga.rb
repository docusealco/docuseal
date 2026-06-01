require "oga"
require_relative "dom_parser"

module MultiXML
  module Parsers
    # XML parser using the Oga library
    #
    # @api private
    module Oga
      extend MultiXML::Parser
      include DomParser
      extend self

      # Exception class raised on Oga parse failure
      # @api private
      ParseError = LL::ParserError

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [LL::ParserError] if XML is malformed
      def parse(io, namespaces: :strip)
        doc = ::Oga.parse_xml(io)
        node_to_hash(doc.children.first, mode: namespaces)
      end

      # Collect child nodes into a hash (Oga-specific implementation)
      #
      # Oga uses different node types than Nokogiri/LibXML.
      #
      # @api private
      # @param node [Oga::XML::Element] Parent node
      # @param node_hash [Hash] Hash to populate
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def collect_children(node, node_hash, mode)
        each_child(node) do |child|
          case child
          when ::Oga::XML::Element then node_to_hash(child, node_hash, mode: mode)
          when ::Oga::XML::Text, ::Oga::XML::Cdata then node_hash[TEXT_CONTENT_KEY] << child.text
          end
        end
      end

      private

      # Iterate over child nodes
      #
      # @api private
      # @param node [Oga::XML::Element] Parent node
      # @return [void]
      def each_child(node, &) = node.children.each(&)

      # Iterate over attribute nodes (excludes xmlns declarations)
      #
      # @api private
      # @param node [Oga::XML::Element] Element node
      # @return [void]
      def each_element_attr(node)
        node.attributes.each do |attr|
          next if oga_xmlns_attr?(attr)

          yield attr
        end
      end

      # Yield each xmlns declaration on this element
      #
      # Oga stores only locally declared namespaces on each element
      # (inherited ones are resolved via lookup, not merged into
      # #namespaces), so we can yield them directly.
      #
      # @api private
      # @param node [Oga::XML::Element] Element node
      # @return [void]
      def each_namespace_decl(node)
        namespace_scope(node).each do |key, ns|
          prefix = (key == "xmlns") ? nil : key
          yield prefix, ns.uri
        end
      end

      # Return [prefix, local] for an element
      #
      # @api private
      # @param node [Oga::XML::Element] Element node
      # @return [Array<String, nil>] prefix and local name
      def element_parts(node)
        [oga_prefix(node.namespace), node.name]
      end

      # Return [prefix, local] for an attribute
      #
      # @api private
      # @param attr [Oga::XML::Attribute] Attribute node
      # @return [Array<String, nil>] prefix and local name
      def attr_parts(attr)
        [oga_prefix(attr.namespace), attr.name]
      end

      # Translate Oga's default-namespace sentinel to nil
      #
      # Oga represents the default namespace with the sentinel name "xmlns";
      # we translate that to nil so it isn't emitted as a prefix.
      #
      # @api private
      # @param namespace [Oga::XML::Namespace, nil] Namespace object
      # @return [String, nil] prefix or nil
      def oga_prefix(namespace)
        return nil unless namespace

        (namespace.name == "xmlns") ? nil : namespace.name
      end

      # Check whether an Oga attribute is actually an xmlns declaration
      #
      # Oga exposes xmlns declarations via Element#namespaces but may also
      # surface them as raw attributes in some cases — filter either shape.
      #
      # @api private
      # @param attr [Oga::XML::Attribute] Attribute node
      # @return [Boolean] true if it's an xmlns declaration
      def oga_xmlns_attr?(attr)
        attr.name == "xmlns" || attr.namespace_name == "xmlns"
      end

      # Local namespace scope for a node
      #
      # @api private
      # @param node [Oga::XML::Element] Element node
      # @return [Hash{String => Oga::XML::Namespace}] scope
      def namespace_scope(node)
        node.namespaces || {}
      end
    end
  end
end
