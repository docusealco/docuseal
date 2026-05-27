module MultiXML
  # Namespace for all supported XML parser backends
  #
  # Each parser (Nokogiri, LibXML, Ox, Oga, REXML, plus SAX variants) is
  # defined as a module under this namespace and exposes a common `parse`
  # and `parse_error` interface.
  #
  # @api private
  module Parsers
    # Shared DOM traversal logic for converting XML nodes to hashes
    #
    # Used by Nokogiri, LibXML, and Oga parsers.
    # Including modules must implement:
    # - each_child(node) { |child| ... }
    # - each_element_attr(node) { |attr| ... } (non-namespace-decl attrs only)
    # - each_namespace_decl(node) { |prefix_or_nil, uri| ... }
    # - element_parts(node) -> [prefix_or_nil, local_name]
    # - attr_parts(attr)    -> [prefix_or_nil, local_name]
    #
    # @api private
    module DomParser
      # Convert an XML node to a hash representation
      #
      # @api private
      # @param node [Object] XML node to convert
      # @param hash [Hash] Accumulator hash for results
      # @param mode [Symbol] Namespace handling mode (:strip, :preserve)
      # @return [Hash] Hash representation of the node
      def node_to_hash(node, hash = {}, mode: :strip)
        node_hash = {TEXT_CONTENT_KEY => +""}
        add_value(hash, format_element_name(node, mode), node_hash)
        collect_children(node, node_hash, mode)
        collect_namespace_decls(node, node_hash, mode)
        collect_attributes(node, node_hash, mode)
        strip_whitespace_content(node_hash)
        hash
      end

      private

      # Add a value to a hash, converting to array on duplicates
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param key [String] Key to add
      # @param value [Object] Value to add
      # @return [void]
      def add_value(hash, key, value)
        existing = hash[key]
        hash[key] = case existing
        when Array then existing << value
        when Hash then [existing, value]
        else value
        end
      end

      # Collect all child nodes into a hash
      #
      # @api private
      # @param node [Object] Parent node
      # @param node_hash [Hash] Hash to populate
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def collect_children(node, node_hash, mode)
        each_child(node) do |child|
          if child.element?
            node_to_hash(child, node_hash, mode: mode)
          elsif text_or_cdata?(child)
            node_hash[TEXT_CONTENT_KEY] << child.content
          end
        end
      end

      # Check if a node is text or CDATA
      #
      # @api private
      # @param node [Object] Node to check
      # @return [Boolean] true if text or CDATA
      def text_or_cdata?(node)
        node.text? || node.cdata?
      end

      # Collect xmlns declarations into the hash under :preserve mode
      #
      # Declarations are unique per prefix on a given element, so no
      # collision handling is needed here.
      #
      # @api private
      # @param node [Object] Node with potential xmlns declarations
      # @param node_hash [Hash] Hash to populate
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def collect_namespace_decls(node, node_hash, mode)
        return unless mode == :preserve

        each_namespace_decl(node) do |prefix, uri|
          node_hash[prefix ? "xmlns:#{prefix}" : "xmlns"] = uri
        end
      end

      # Collect all attributes from a node
      #
      # Attributes arrive after child elements. When an attribute collides
      # with a child of the same name, the attribute is placed first in the
      # resulting array (e.g. `<user name="A"><name>B</name></user>` →
      # `["A", "B"]`). See `test/attribute_tests.rb`.
      #
      # @api private
      # @param node [Object] Node with attributes
      # @param node_hash [Hash] Hash to populate
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def collect_attributes(node, node_hash, mode)
        each_element_attr(node) do |attr|
          add_attribute_value(node_hash, format_attr_name(attr, mode), attr.value)
        end
      end

      # Format an element's name according to the namespace mode
      #
      # @api private
      # @param node [Object] Element node
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted element name
      def format_element_name(node, mode)
        format_name(*element_parts(node), mode)
      end

      # Format an attribute's name according to the namespace mode
      #
      # @api private
      # @param attr [Object] Attribute node
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted attribute name
      def format_attr_name(attr, mode)
        format_name(*attr_parts(attr), mode)
      end

      # Produce a name string for a given [prefix, local] tuple
      #
      # @api private
      # @param prefix [String, nil] Namespace prefix (nil for default / unprefixed)
      # @param local [String] Local part of the name
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted name
      def format_name(prefix, local, mode)
        (mode == :preserve && prefix) ? "#{prefix}:#{local}" : local
      end

      # Add an attribute value, preserving attr-before-child collision order
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param key [String] Attribute key
      # @param value [String] Attribute value
      # @return [void]
      def add_attribute_value(hash, key, value)
        existing = hash[key]
        hash[key] = case existing
        when nil then value
        when Array then insert_attribute_before_children(existing, value)
        when Hash then [value, existing]
        else [existing, value]
        end
      end

      # Insert a later attribute before any child-element entries
      #
      # @api private
      # @param values [Array] Existing colliding values
      # @param value [String] Attribute value to insert
      # @return [Array] Updated value list
      def insert_attribute_before_children(values, value)
        child_index = values.index { |entry| entry.is_a?(Hash) } || values.length
        values.dup.insert(child_index, value)
      end

      # Remove empty or whitespace-only text content
      #
      # @api private
      # @param node_hash [Hash] Hash to clean up
      # @return [void]
      def strip_whitespace_content(node_hash)
        content = node_hash[TEXT_CONTENT_KEY]
        should_remove = content.empty? || (node_hash.size > 1 && content.strip.empty?)
        node_hash.delete(TEXT_CONTENT_KEY) if should_remove
      end
    end
  end
end
