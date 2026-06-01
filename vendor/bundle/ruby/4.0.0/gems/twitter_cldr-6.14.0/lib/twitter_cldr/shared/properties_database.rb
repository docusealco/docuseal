# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'set'

module TwitterCldr
  module Shared

    class PropertiesDatabase
      include TwitterCldr::Utils

      DEFAULT_ROOT_PATH = File.join(
        TwitterCldr::RESOURCES_DIR, 'unicode_data', 'properties'
      )

      attr_reader :root_path, :trie

      def initialize(root_path = DEFAULT_ROOT_PATH)
        @root_path = root_path
        @trie = FileSystemTrie.new(root_path)
      end

      def store(property_name, property_value, data)
        trie.add(key_for(property_name, property_value), data)
      end

      def code_points_for_property(property_name, property_value = nil)
        key = key_for(property_name, property_value)
        node = trie.get_node(key)

        if node
          if node.value
            node.value
          elsif name_indicates_value_prefix?(property_name)
            concat_children(key)
          else
            RangeSet.new([])
          end
        else
          RangeSet.new([])
        end
      end

      def include?(property_name, property_value = nil)
        values = property_values_for(property_name)

        if property_value
          property_names.include?(property_name) &&
            values && values.include?(property_value)
        else
          property_names.include?(property_name)
        end
      end

      def properties_for_code_point(code_point)
        code_point_cache[code_point] ||=
          PropertySet.new(lookup_code_point(code_point))
      end

      # List of property names
      # @return [Array<String>] Array of property names string
      # @example
      #   TwitterCldr::Shared::CodePoint.properties.property_names
      #   # => ["ASCII_Hex_Digit", "Age", "Alphabetic", … ]
      def property_names
        glob = File.join(root_path, '*')
        @property_names ||= Dir.glob(glob).map do |path|
          File.basename(path)
        end
      end

      # Return possible values for a given property
      # @param property_name [String] Property name
      # @return [Array<String>|nil] List of values Values
      # @example
      #   TwitterCldr::Shared::CodePoint.properties.property_values_for('Script')
      #   # => ["Adlam", "Ahom", "Anatolian_Hieroglyphs", … ]
      # TwitterCldr::Shared::CodePoint.properties.property_values_for('Alphabetic') # => nil
      def property_values_for(property_name)
        if property_values.include?(property_name)
          return property_values[property_name]
        end

        prefix = File.join(root_path, property_name)
        glob = File.join(prefix, "**/**/#{FileSystemTrie::VALUE_FILE}")

        values = Dir.glob(glob).map do |path|
          path = File.dirname(path)[(prefix.length + 1)..-1]
          path.split(File::SEPARATOR).join if path
        end.compact

        if name_indicates_value_prefix?(property_name)
          values += values.map { |v| v[0] }
        end

        property_values[property_name] = if values.length == 0
          nil
        else
          values.uniq
        end
      end

      def each_property_pair
        if block_given?
          property_names.each do |property_name|
            if property_values = property_values_for(property_name)
              property_values.each do |property_value|
                yield property_name, property_value
              end
            else
              yield property_name, nil
            end
          end
        else
          to_enum(__method__)
        end
      end

      def normalize(property_name, property_value = nil)
        normalizer.normalize(property_name, property_value)
      end

      private

      def normalizer
        @normalizer ||= PropertyNormalizer.new(self)
      end

      def lookup_code_point(code_point)
        {}.tap do |properties|
          each_property_pair do |property_name, property_value|
            code_points = code_points_for_property(
              property_name, property_value
            )

            if code_points.include?(code_point)
              if property_value
                properties[property_name] ||= Set.new
                properties[property_name] << property_value
              else
                properties[property_name] = nil
              end
            end
          end
        end
      end

      def property_values
        @property_values ||= {}
      end

      def code_point_cache
        @code_point_cache ||= {}
      end

      def concat_children(key)
        glob = File.join(root_path, *key, "**/**/#{FileSystemTrie::VALUE_FILE}")

        Dir.glob(glob).inject(RangeSet.new([])) do |ret, entry|
          key = File.dirname(entry)
          key = key[(root_path.length + 1)..-1].split(File::SEPARATOR)

          if value = trie.get(key)
            ret.union(value)
          else
            ret
          end
        end
      end

      def key_for(property_name, property_value)
        if property_value
          if name_indicates_value_prefix?(property_name)
            [property_name] + property_value.chars.to_a
          else
            [property_name, property_value]
          end
        else
          [property_name]
        end
      end

      def name_indicates_value_prefix?(property_name)
        property_name == 'General_Category' ||
          property_name == 'gc'
      end
    end

  end
end
