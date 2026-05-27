# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Collation

    # SortKeyBuilder builds a collation sort key from an array of collation elements.
    #
    # Weights compression algorithms for every level are described in
    # http://source.icu-project.org/repos/icu/icuhtml/trunk/design/collation/ICU_collation_design.htm
    #
    class SortKeyBuilder

      PRIMARY_LEVEL, SECONDARY_LEVEL, TERTIARY_LEVEL = 0, 1, 2

      LEVEL_SEPARATOR = 1 # separate levels in a sort key '01' bytes

      VALID_CASE_FIRST_OPTIONS    = [nil, :lower, :upper]
      VALID_MAXIMUM_LEVEL_OPTIONS = [nil, 1, 2, 3]

      attr_reader :collation_elements, :case_first

      # Returns a sort key as an array of bytes.
      #
      # Arguments:
      #
      #   collation_elements - an array of collation elements, represented as arrays of integer weights.
      #   options            - hash of options:
      #     case_first       - optional case-first sorting order setting: :upper, :lower, nil (discard case bits).
      #     maximum_level    - only append weights to maximum level specified (1 or 2), can be useful for searching/matching applications
      #
      # An instance of the class is created only to prevent passing of @collation_elements and @bytes_array from one
      # method into another while forming the sort key.
      #
      def self.build(collation_elements, options = nil)
        new(collation_elements, options).bytes_array
      end

      # Arguments:
      #
      #   collation_elements - an array of collation elements, represented as arrays of integer weights.
      #   options            - hash of options:
      #     case_first       - optional case-first sorting order setting: :upper, :lower, nil (discard case bits).
      #     maximum_level    - only append weights to maximum level specified (1 or 2), can be useful for searching/matching applications
      #
      def initialize(collation_elements, options = {})
        raise ArgumentError, "second argument should be an options hash, not `#{options}`. Do you mean `:case_first => #{options}`?" unless options.kind_of? Hash

        case_first = options[:case_first]
        raise ArgumentError, "invalid case-first options '#{case_first.inspect}'" unless VALID_CASE_FIRST_OPTIONS.include?(case_first)

        maximum_level = options[:maximum_level]
        raise ArgumentError, "invalid maximum_level option 'options[:maximum_level]'" unless VALID_MAXIMUM_LEVEL_OPTIONS.include?(maximum_level)

        @collation_elements = collation_elements
        @case_first         = case_first
        @maximum_level      = maximum_level

        init_tertiary_constants
      end

      def bytes_array
        @bytes_array ||= build_bytes_array
      end

      private

      def build_bytes_array
        @bytes_array = []

        append_primary_bytes
        append_secondary_bytes unless @maximum_level && (@maximum_level < 2)
        append_tertiary_bytes  unless @maximum_level && (@maximum_level < 3)

        @bytes_array
      end

      def append_primary_bytes
        @last_leading_byte = nil

        @collation_elements.each do |collation_element|
          bytes = integer_to_bytes_array(level_weight(collation_element, PRIMARY_LEVEL))

          unless bytes.empty?
            leading_byte = bytes.shift

            if leading_byte != @last_leading_byte
              @bytes_array << (leading_byte < @last_leading_byte ? PRIMARY_BYTE_MIN : PRIMARY_BYTE_MAX) if @last_leading_byte
              @bytes_array << leading_byte

              @last_leading_byte = !bytes.empty? && compressible_primary?(leading_byte) ? leading_byte : nil
            end

            @bytes_array.concat(bytes)
          end
        end
      end

      def compressible_primary?(leading_byte)
        (MIN_NON_LATIN_PRIMARY..MAX_REGULAR_PRIMARY).include?(leading_byte)
      end

      def append_secondary_bytes
        @bytes_array << LEVEL_SEPARATOR

        @common_count = 0

        @collation_elements.each do |collation_element|
          integer_to_bytes_array(level_weight(collation_element, SECONDARY_LEVEL)).each do |byte|
            append_secondary_byte(byte)
          end
        end

        # append compressed trailing common bytes
        append_common_bytes(SECONDARY_BOTTOM, SECONDARY_BOTTOM_COUNT, false) if @common_count > 0
      end

      def append_tertiary_bytes
        @bytes_array << LEVEL_SEPARATOR

        @common_count = 0

        @collation_elements.each do |collation_element|
          integer_to_bytes_array(tertiary_weight(collation_element)).each do |byte|
            append_tertiary_byte(byte)
          end
        end

        # append compressed trailing common bytes
        if @common_count > 0
          if @tertiary_common == TERTIARY_BOTTOM_NORMAL
            append_common_bytes(@tertiary_bottom, @tertiary_bottom_count, false)
          else
            append_common_bytes(@tertiary_top, @tertiary_top_count, true)
            @bytes_array[-1] -= 1 # make @bytes_array[-1] = boundary - @common_count (for compatibility with ICU)
          end
        end
      end

      def append_secondary_byte(secondary)
        if secondary == SECONDARY_COMMON
          @common_count += 1
        else
          append_with_common_bytes(secondary, SECONDARY_COMMON_SPACE)
        end
      end

      def append_tertiary_byte(tertiary)
        if tertiary == @tertiary_common
          @common_count += 1
        else
          if @tertiary_common == TERTIARY_COMMON_NORMAL && @tertiary_common < tertiary
            tertiary += @tertiary_addition
          elsif @tertiary_common == TERTIARY_COMMON_UPPER_FIRST && tertiary <= @tertiary_common
            tertiary -= @tertiary_addition
          end

          append_with_common_bytes(tertiary, @tertiary_common_space)
        end
      end

      def append_with_common_bytes(byte, options)
        if @common_count > 0
          if byte < options[:common]
            append_common_bytes(options[:bottom], options[:bottom_count], false)
          else
            append_common_bytes(options[:top], options[:top_count], true)
          end
        end

        @bytes_array << byte
      end

      def append_common_bytes(boundary, count_limit, top)
        sign = top ? -1 : +1

        while @common_count > count_limit
          @bytes_array << boundary + sign * count_limit
          @common_count -= count_limit
        end

        @bytes_array << boundary + sign * (@common_count - 1)
        @common_count = 0
      end

      def tertiary_weight(collation_element)
        weight = level_weight(collation_element, TERTIARY_LEVEL)

        if continuation?(weight)
          remove_continuation_bits(weight)
        else
          (weight & @tertiary_mask) ^ @case_switch
        end
      end

      def level_weight(collation_element, level)
        collation_element[level] || 0
      end

      def integer_to_bytes_array(number)
        bytes = []

        while number > 0
          bytes.unshift(number & 0xFF)
          number >>= 8
        end

        bytes
      end

      def continuation?(weight)
        weight & CASE_BITS_MASK == CASE_BITS_MASK
      end

      def remove_continuation_bits(weight)
        weight & REMOVE_CASE_MASK
      end

      def init_tertiary_constants
        @case_switch = @case_first == :upper ? CASE_SWITCH : NO_CASE_SWITCH

        if @case_first
          @tertiary_mask     = KEEP_CASE_MASK
          @tertiary_addition = TERTIARY_ADDITION_CASE_FIRST

          if @case_first == :upper
            @tertiary_common = TERTIARY_COMMON_UPPER_FIRST
            @tertiary_top    = TERTIARY_TOP_UPPER_FIRST
            @tertiary_bottom = TERTIARY_BOTTOM_UPPER_FIRST
          else # @case_first == :lower
            @tertiary_common = TERTIARY_COMMON_NORMAL
            @tertiary_top    = TERTIARY_TOP_LOWER_FIRST
            @tertiary_bottom = TERTIARY_BOTTOM_LOWER_FIRST
          end
        else
          @tertiary_mask     = REMOVE_CASE_MASK
          @tertiary_addition = TERTIARY_ADDITION_NORMAL

          @tertiary_common = TERTIARY_COMMON_NORMAL
          @tertiary_top    = TERTIARY_TOP_NORMAL
          @tertiary_bottom = TERTIARY_BOTTOM_NORMAL
        end

        total_tertiary_count   = @tertiary_top - @tertiary_bottom - 1
        @tertiary_top_count    = (TERTIARY_PROPORTION * total_tertiary_count).to_i
        @tertiary_bottom_count = total_tertiary_count - @tertiary_top_count

        @tertiary_common_space = {
            common:       @tertiary_common,
            bottom:       @tertiary_bottom,
            bottom_count: @tertiary_bottom_count,
            top:          @tertiary_top,
            top_count:    @tertiary_top_count
        }
      end

      # Primary level compression constants

      PRIMARY_BYTE_MIN = 0x3
      PRIMARY_BYTE_MAX = 0xFF

      MIN_NON_LATIN_PRIMARY = 0x5B
      MAX_REGULAR_PRIMARY   = 0x7A

      # Secondary level compression constants

      SECONDARY_BOTTOM       = 0x05
      SECONDARY_TOP          = 0x86
      SECONDARY_PROPORTION   = 0.5
      SECONDARY_COMMON       = SECONDARY_BOTTOM
      SECONDARY_TOTAL_COUNT  = SECONDARY_TOP - SECONDARY_BOTTOM - 1
      SECONDARY_TOP_COUNT    = (SECONDARY_PROPORTION * SECONDARY_TOTAL_COUNT).to_i
      SECONDARY_BOTTOM_COUNT = SECONDARY_TOTAL_COUNT - SECONDARY_TOP_COUNT

      SECONDARY_COMMON_SPACE = {
          common:       SECONDARY_COMMON,
          bottom:       SECONDARY_BOTTOM,
          bottom_count: SECONDARY_BOTTOM_COUNT,
          top:          SECONDARY_TOP,
          top_count:    SECONDARY_TOP_COUNT
      }

      # Tertiary level compression constants

      REMOVE_CASE_MASK = 0x3F
      KEEP_CASE_MASK   = 0xFF

      CASE_BITS_MASK = 0xC0

      CASE_SWITCH    = 0xC0
      NO_CASE_SWITCH = 0

      TERTIARY_ADDITION_NORMAL     = 0x80
      TERTIARY_ADDITION_CASE_FIRST = 0x40

      TERTIARY_PROPORTION = 0.667

      # Normal (case-first disabled)
      TERTIARY_BOTTOM_NORMAL = 0x05
      TERTIARY_TOP_NORMAL    = 0x85
      TERTIARY_COMMON_NORMAL = TERTIARY_BOTTOM_NORMAL

      # Lower first
      TERTIARY_BOTTOM_LOWER_FIRST = TERTIARY_BOTTOM_NORMAL
      TERTIARY_TOP_LOWER_FIRST    = 0x45
      TERTIARY_COMMON_LOWER_FIRST = TERTIARY_BOTTOM_LOWER_FIRST

      # Upper first
      TERTIARY_BOTTOM_UPPER_FIRST = 0x86
      TERTIARY_TOP_UPPER_FIRST    = 0xC5
      TERTIARY_COMMON_UPPER_FIRST = TERTIARY_TOP_UPPER_FIRST

    end

  end
end
