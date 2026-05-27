require "rexml/document"

module MultiXML
  module Parsers
    # XML parser using Ruby's built-in REXML library
    #
    # @api private
    module Rexml
      extend MultiXML::Parser
      extend self

      # Exception class raised on REXML parse failure
      # @api private
      ParseError = ::REXML::ParseException

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [REXML::ParseException] if XML is malformed
      def parse(io, namespaces: :strip)
        doc = REXML::Document.new(io)
        element_to_hash({}, doc.root, namespaces)
      end

      private

      # Convert an element to hash format
      #
      # @api private
      # @param hash [Hash] Accumulator hash
      # @param element [REXML::Element] Element to convert
      # @param mode [Symbol] Namespace handling mode
      # @return [Hash] Updated hash
      def element_to_hash(hash, element, mode)
        add_to_hash(hash, format_element_name(element, mode), collapse_element(element, mode))
      end

      # Format element name using prefix/local and namespace mode
      #
      # @api private
      # @param element [REXML::Element] Element node
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted element name
      def format_element_name(element, mode)
        format_name(element.prefix, element.name, mode)
      end

      # Format attribute name using prefix/local and namespace mode
      #
      # @api private
      # @param attr [REXML::Attribute] Attribute node
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted attribute name
      def format_attr_name(attr, mode)
        format_name(attr.prefix, attr.name, mode)
      end

      # Produce a name string for a given [prefix, local] tuple
      #
      # @api private
      # @param prefix [String, nil] Namespace prefix
      # @param local [String] Local part of the name
      # @param mode [Symbol] Namespace handling mode
      # @return [String] formatted name
      def format_name(prefix, local, mode)
        (mode == :preserve && prefix && !prefix.empty?) ? "#{prefix}:#{local}" : local
      end

      # Collapse an element into a hash with attributes and content
      #
      # @api private
      # @param element [REXML::Element] Element to collapse
      # @param mode [Symbol] Namespace handling mode
      # @return [Hash] Hash representation
      def collapse_element(element, mode)
        node_hash = collect_attributes(element, mode)

        if element.has_elements?
          collect_child_elements(element, node_hash, mode)
          add_text_content(node_hash, element) unless whitespace_only?(element)
        elsif node_hash.empty? || !whitespace_only?(element)
          add_text_content(node_hash, element)
        end

        node_hash
      end

      # Collect all attributes from an element into a hash
      #
      # @api private
      # @param element [REXML::Element] Element with attributes
      # @param mode [Symbol] Namespace handling mode
      # @return [Hash] Hash of attribute name-value pairs
      def collect_attributes(element, mode)
        element.attributes.each_attribute.with_object({}) do |attr, hash|
          if xmlns_decl?(attr)
            add_attribute_value(hash, xmlns_decl_key(attr), attr.value) if mode == :preserve
          else
            add_attribute_value(hash, format_attr_name(attr, mode), attr.value)
          end
        end
      end

      # Check whether an attribute represents an xmlns declaration
      #
      # @api private
      # @param attr [REXML::Attribute] Attribute to inspect
      # @return [Boolean] true if xmlns declaration
      def xmlns_decl?(attr)
        attr.prefix == "xmlns" || ((attr.prefix.nil? || attr.prefix.empty?) && attr.name == "xmlns")
      end

      # Build the key for an xmlns declaration under :preserve
      #
      # @api private
      # @param attr [REXML::Attribute] Declaration attribute
      # @return [String] key such as "xmlns" or "xmlns:atom"
      def xmlns_decl_key(attr)
        (attr.prefix == "xmlns") ? "xmlns:#{attr.name}" : "xmlns"
      end

      # Collect all child elements into a hash
      #
      # @api private
      # @param element [REXML::Element] Parent element
      # @param node_hash [Hash] Hash to populate
      # @param mode [Symbol] Namespace handling mode
      # @return [void]
      def collect_child_elements(element, node_hash, mode)
        element.each_element { |child| element_to_hash(node_hash, child, mode) }
      end

      # Add text content from an element to a hash
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param element [REXML::Element] Element with text
      # @return [Hash] Updated hash
      def add_text_content(hash, element)
        return hash unless element.has_text?

        text = element.texts.map(&:value).join
        add_to_hash(hash, TEXT_CONTENT_KEY, text)
      end

      # Add a value to a hash, handling duplicates as arrays
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param key [String] Key to add
      # @param value [Object] Value to add
      # @return [Hash] Updated hash
      def add_to_hash(hash, key, value)
        existing = hash[key]
        hash[key] = if existing
          existing.is_a?(Array) ? existing << value : [existing, value]
        elsif value.is_a?(Array)
          [value]
        else
          value
        end
        hash
      end

      # Add an attribute value while keeping document order on collisions
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param key [String] Attribute key
      # @param value [String] Attribute value
      # @return [Hash] Updated hash
      def add_attribute_value(hash, key, value)
        existing = hash[key]
        hash[key] = case existing
        when nil then value
        when Array then insert_attribute_before_children(existing, value)
        when Hash then [value, existing]
        else [existing, value]
        end
        hash
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

      # Check if element contains only whitespace text
      #
      # @api private
      # @param element [REXML::Element] Element to check
      # @return [Boolean] true if whitespace only
      def whitespace_only?(element)
        element.texts.join.strip.empty?
      end
    end
  end
end
