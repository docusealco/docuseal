# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared

    class CodePoint
      DECOMPOSITION_REGEX = /^(?:<(.+)>\s+)?(.+)?$/
      MAX_CODE_POINT = 1_112_111

      attr_reader :fields

      def code_point
        @fields[0]
      end

      def name
        @fields[1]
      end

      def category
        @fields[2]
      end

      def combining_class
        @fields[3]
      end

      def bidi_class
        @fields[4]
      end

      def decomposition
        @decomposition ||= begin
          decomp = fields[5]
          if decomp =~ DECOMPOSITION_REGEX
            $2 && $2.split.map(&:hex)
          else
            raise ArgumentError,
              "decomposition #{decomp.inspect} has invalid format"
          end
        end
      end

      def compatibility_decomposition_tag
        @compat_decomp_tag ||= begin
          decomp = fields[5]
          if decomp =~ DECOMPOSITION_REGEX
            $1
          else
            raise ArgumentError,
              "decomposition #{decomp.inspect} has invalid format"
          end
        end
      end

      def digit_value
        @fields[6]
      end

      def non_decimal_digit_value
        @fields[7]
      end

      def numeric_value
        @fields[8]
      end

      def bidi_mirrored
        @fields[9]
      end

      def unicode1_name
        @fields[10]
      end

      def iso_comment
        @fields[11]
      end

      def simple_uppercase_map
        @uppercase ||= field_or_nil(12) do |val|
          [val.to_i(16)].pack('U*')
        end
      end

      def simple_lowercase_map
        @lowercase ||= field_or_nil(13) do |val|
          [val.to_i(16)].pack('U*')
        end
      end

      def simple_titlecase_map
        @titlecase ||= field_or_nil(14) do |val|
          [val.to_i(16)].pack('U*')
        end
      end

      def initialize(fields)
        @fields = fields
      end

      def properties
        self.class.properties.properties_for_code_point(code_point)
      end

      private

      def field_or_nil(index)
        val = @fields[index]
        if val && !val.empty?
          yield val
        end
      end

      class << self

        include Enumerable

        def get(code_point)
          code_point_cache[code_point] ||= begin
            target = get_block(code_point)

            return unless target && target.first

            block_data      = TwitterCldr.get_resource(:unicode_data, :blocks, target.first)
            code_point_data = block_data.fetch(code_point) { |cp| get_range_start(cp, block_data) }

            CodePoint.new(code_point_data) if code_point_data
          end
        end

        def properties
          @properties ||= TwitterCldr::Shared::PropertiesDatabase.new
        end

        def code_points_for_property(property_name, property_value = nil)
          properties.code_points_for_property(
            property_name, property_value
          )
        end

        def properties_for_code_point(code_point)
          properties.properties_for_code_point(code_point)
        end

        def each
          if block_given?
            (0..max).each do |cp|
              if found_cp = get(cp)
                yield found_cp
              end
            end
          else
            to_enum(__method__)
          end
        end

        def max
          MAX_CODE_POINT
        end

        private

        def code_point_cache
          @code_point_cache ||= {}
        end

        def get_block(code_point)
          block_cache[code_point] ||= blocks.detect do |_, range|
            range.include?(code_point)
          end
        end

        def block_cache
          @block_cache ||= {}
        end

        def blocks
          @blocks ||= TwitterCldr.get_resource(
            :unicode_data, :blocks
          )
        end

        # Check if block constitutes a range. The code point beginning a range will have a name enclosed in <>, ending with 'First'
        # eg: <CJK Ideograph Extension A, First>
        # http://unicode.org/reports/tr44/#Code_Point_Ranges
        def get_range_start(code_point, block_data)
          start_data = block_data[block_data.keys.min]

          if start_data[1] =~ /<.*, First>/
            start_data = start_data.clone
            start_data[0] = code_point
            start_data[1] = start_data[1].sub(', First', '')
            start_data
          end
        end

      end
    end
  end
end
