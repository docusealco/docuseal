require "nokogiri"
require_relative "dom_parser"

module MultiXML
  module Parsers
    # XML parser using the Nokogiri library
    #
    # @api private
    module Nokogiri
      extend MultiXML::Parser
      include DomParser
      extend self

      # Exception class raised on Nokogiri parse failure
      # @api private
      ParseError = ::Nokogiri::XML::SyntaxError

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [Nokogiri::XML::SyntaxError] if XML is malformed
      def parse(io, namespaces: :strip)
        doc = ::Nokogiri::XML(io)
        raise doc.errors.first unless doc.errors.empty?

        node_to_hash(doc.root, mode: namespaces)
      end

      private

      # Iterate over child nodes
      #
      # @api private
      # @param node [Nokogiri::XML::Node] Parent node
      # @return [void]
      def each_child(node, &) = node.children.each(&)

      # Iterate over attribute nodes (excludes xmlns declarations)
      #
      # @api private
      # @param node [Nokogiri::XML::Node] Element node
      # @return [void]
      def each_element_attr(node, &) = node.attribute_nodes.each(&)

      # Yield each xmlns declaration on this element
      #
      # @api private
      # @param node [Nokogiri::XML::Node] Element node
      # @return [void]
      def each_namespace_decl(node)
        node.namespace_definitions.each { |ns| yield ns.prefix, ns.href }
      end

      # Return [prefix, local] for an element
      #
      # @api private
      # @param node [Nokogiri::XML::Node] Element node
      # @return [Array<String, nil>] prefix and local name
      def element_parts(node)
        [node.namespace&.prefix, node.name]
      end

      # Return [prefix, local] for an attribute
      #
      # @api private
      # @param attr [Nokogiri::XML::Attr] Attribute node
      # @return [Array<String, nil>] prefix and local name
      def attr_parts(attr)
        [attr.namespace&.prefix, attr.name]
      end
    end
  end
end
