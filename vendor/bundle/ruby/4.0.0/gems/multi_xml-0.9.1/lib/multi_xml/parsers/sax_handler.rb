require "cgi/escape"

module MultiXML
  module Parsers
    # Shared SAX handler logic for building hash trees from XML events.
    #
    # Provides a stack machine used by both NokogiriSax and LibxmlSax
    # handlers. Parser-specific subclasses translate their native callbacks
    # into calls on this entrypoint:
    #
    # - handle_start_element_ns(local, prefix, attr_tuples, ns_decls)
    #     where attr_tuples = [[attr_prefix_or_nil, local, value], ...]
    #           ns_decls    = [[prefix_or_nil, uri], ...]
    #
    # @api private
    module SaxHandler
      # Initialize the handler state
      #
      # @api private
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def initialize_handler(mode)
        @mode = mode
        @result = {}
        @stack = [@result]
        @pending = []
      end

      # Get the parsed result
      #
      # @api private
      # @return [Hash] the parsed hash
      attr_reader :result

      private

      # Get the current element hash on top of the stack
      #
      # @api private
      # @return [Hash] current hash being built
      def current = @stack.last

      # Entry point for namespace-aware start events
      #
      # @api private
      # @param local [String] Local element name
      # @param prefix [String, nil] Element namespace prefix
      # @param attr_tuples [Array] Attributes as [prefix, local, value]
      # @param ns_decls [Array] xmlns declarations as [prefix, uri] pairs
      # @return [void]
      def handle_start_element_ns(local, prefix, attr_tuples, ns_decls)
        child = {TEXT_CONTENT_KEY => +""}
        add_child_to_current(format_name(prefix, local), child)
        @stack << child

        @pending << build_pending_attrs(ns_decls, attr_tuples)
      end

      # Apply attributes and pop the current element from the stack
      #
      # @api private
      # @return [void]
      def handle_end_element
        @pending.pop.each { |key, value| add_attr_to_current(key, value) }
        strip_whitespace_content
        @stack.pop
      end

      # Append text to the current element's content
      #
      # @api private
      # @param text [String] Text to append
      # @return [void]
      def append_text(text)
        current[TEXT_CONTENT_KEY] << text
      end

      # Build the list of attributes to apply at element-end
      #
      # @api private
      # @param ns_decls [Array] xmlns declarations
      # @param attr_tuples [Array] Attribute [prefix, local, value] tuples
      # @return [Array<Array>] list of [key, value] pairs
      def build_pending_attrs(ns_decls, attr_tuples)
        preserved_ns_decls(ns_decls) + attr_tuples.map do |prefix, local, value|
          [format_name(prefix, local), CGI.unescapeHTML(value)]
        end
      end

      # Transform xmlns declarations into attribute pairs for :preserve mode
      #
      # @api private
      # @param ns_decls [Array] Declarations as [prefix, uri]
      # @return [Array<Array>] [xmlns key, uri] pairs (empty outside :preserve)
      def preserved_ns_decls(ns_decls)
        return [] unless @mode == :preserve

        ns_decls.map { |prefix, uri| [prefix ? "xmlns:#{prefix}" : "xmlns", uri] }
      end

      # Produce a name string for a [prefix, local] tuple
      #
      # @api private
      # @param prefix [String, nil] Namespace prefix
      # @param local [String] Local part of the name
      # @return [String] formatted name
      def format_name(prefix, local)
        (@mode == :preserve && prefix) ? "#{prefix}:#{local}" : local
      end

      # Add a child element to the current hash, folding on collision
      #
      # @api private
      # @param name [String] Child element name
      # @param child [Hash] Child hash to add
      # @return [void]
      def add_child_to_current(name, child)
        existing = current[name]
        current[name] = case existing
        when Array then existing << child
        when Hash then [existing, child]
        else child
        end
      end

      # Add an attribute value to the current hash (attr wins on collision)
      #
      # Attributes are applied at end_element, after children have already
      # populated the hash. When an attribute collides with a child of the
      # same local name, the attribute is placed first in the resulting
      # array (matching DomParser / REXML behavior and existing tests).
      #
      # @api private
      # @param key [String] Attribute key
      # @param value [String] Attribute value
      # @return [void]
      def add_attr_to_current(key, value)
        existing = current[key]
        current[key] = case existing
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

      # Remove empty or whitespace-only text content from the current hash
      #
      # @api private
      # @return [void]
      def strip_whitespace_content
        content = current[TEXT_CONTENT_KEY]
        should_remove = content.empty? || (current.size > 1 && content.strip.empty?)
        current.delete(TEXT_CONTENT_KEY) if should_remove
      end
    end
  end
end
