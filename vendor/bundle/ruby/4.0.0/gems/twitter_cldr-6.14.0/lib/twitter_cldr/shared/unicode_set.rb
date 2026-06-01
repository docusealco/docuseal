# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    class UnicodeSet

      attr_reader :set

      def initialize(initial = [])
        @set = TwitterCldr::Utils::RangeSet.from_array(initial)
      end

      def apply_pattern(pattern)
        re = TwitterCldr::Shared::UnicodeRegex.compile(pattern)

        re.elements.each do |element|
          element.to_set.ranges.each do |range|
            set << range
          end
        end

        self
      end

      def apply_property(property_name, property_value = nil)
        set.union!(
          TwitterCldr::Shared::CodePoint.properties.code_points_for_property(
            property_name, property_value
          )
        )
      end

      def add(codepoint)
        add_range(codepoint..codepoint)
      end

      def add_range(range)
        set << range
        self
      end

      def add_set(unicode_set)
        set.union!(unicode_set.set)
        self
      end

      def add_list(list)
        set.union!(self.class.new(list).set)
      end

      def subtract(codepoint)
        subtract_range(codepoint..codepoint)
      end

      def subtract_range(range)
        set.subtract!(TwitterCldr::Utils::RangeSet.new([range]))
        self
      end

      def each(&block)
        set.each(&block)
      end

      def include?(codepoint)
        set.include?(codepoint)
      end

      def to_set
        set.to_set
      end

    end
  end
end
