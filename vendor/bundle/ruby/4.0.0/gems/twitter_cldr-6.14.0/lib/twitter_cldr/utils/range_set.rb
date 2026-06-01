# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'set'

module TwitterCldr
  module Utils

    # An integer set, implemented under the hood with ranges. The idea is
    # that it's more efficient to store sequential data in ranges rather
    # than as single elements. By definition, RangeSets contain no duplicates.
    class RangeSet

      include Enumerable

      attr_reader :ranges

      class << self

        def from_array(array)
          new(rangify(array))
        end

        # Turns an array of integers into ranges. The "compress" option indicates
        # whether or not to turn isolated elements into zero-length ranges or leave
        # them as single elements.
        #
        # For example:
        # rangify([1, 2, 4], false) returns [1..2, 4..4]
        # rangify([1, 2, 4], true) returns [1..2, 4]
        def rangify(list, compress = false)
          last_item = nil

          list.sort.inject([]) do |ret, item|
            if last_item
              diff = item - last_item

              if diff > 0
                if diff == 1
                  ret[-1] << item
                else
                  ret << [item]
                end

                last_item = item
              end
            else
              ret << [item]
              last_item = item
            end

            ret
          end.map do |sub_list|
            if compress && sub_list.size == 1
              sub_list.first
            else
              sub_list.first..sub_list.last
            end
          end
        end

      end

      def initialize(ranges)
        @ranges = ranges
        flatten
      end

      def to_a(compress = false)
        if compress
          ranges.map do |range|
            if range.first == range.last
              range.first
            else
              range
            end
          end
        else
          ranges.dup
        end
      end

      def to_full_a
        ranges.inject([]) do |ret, range|
          ret + range.to_a
        end
      end

      def to_set
        Set.new(to_full_a)
      end

      def include?(obj)
        case obj
          when Numeric
            includes_numeric?(obj)
          when Range
            includes_range?(obj)
          else
            false
        end
      end

      def empty?
        ranges.empty?
      end

      def <<(range)
        ranges << range
        flatten
      end

      def union(range_set)
        self.class.new(range_set.ranges + ranges)
      end

      def union!(range_set)
        ranges.concat(range_set.ranges)
        flatten
      end

      def intersection(range_set)
        new_ranges = []

        range_set.ranges.each do |their_range|
          ranges.each do |our_range|
            if overlap?(their_range, our_range)
              if intrsc = find_intersection(our_range, their_range)
                new_ranges << intrsc
              end
            end
          end
        end

        self.class.new(new_ranges)
      end

      def subtract(range_set)
        return self if range_set.empty?
        remaining = range_set.ranges.dup
        current_ranges = ranges.dup
        new_ranges = []

        while their_range = remaining.shift
          new_ranges = []

          current_ranges.each do |our_range|
            if overlap?(their_range, our_range)
              new_ranges += find_subtraction(their_range, our_range)
            else
              new_ranges << our_range
            end
          end

          current_ranges = new_ranges
        end

        self.class.new(new_ranges)
      end

      def subtract!(range_set)
        @ranges = subtract(range_set).ranges
      end

      # symmetric difference (the union without the intersection)
      # http://en.wikipedia.org/wiki/Symmetric_difference
      def difference(range_set)
        union(range_set).subtract(intersection(range_set))
      end

      def each_range(&block)
        ranges.each(&block)
      end

      def each(&block)
        if block_given?
          ranges.each do |range|
            range.each(&block)
          end
        else
          to_enum(__method__)
        end
      end

      def size
        ranges.inject(0) do |sum, range|
          sum + range_length(range)
        end
      end

      private

      def range_length(range)
        len = (range.last - range.first)
        range.exclude_end? ? len : len + 1
      end

      def includes_numeric?(num)
        result = bsearch do |range|
          if num >= range.first && num <= range.last
            0
          elsif num < range.first
            -1
          else
            1
          end
        end

        !!result
      end

      def includes_range?(range)
        result = bsearch do |cur_range|
          fo = front_overlap?(cur_range, range)
          ro = rear_overlap?(cur_range, range)

          return false if fo || ro

          if full_overlap?(cur_range, range)
            0
          elsif range.first < cur_range.first
            -1
          else
            1
          end
        end

        !!result
      end

      def bsearch
        low = 0
        mid = 0
        high = ranges.size - 1

        while low <= high
          mid = (low + high) / 2

          case yield(ranges[mid])
            when 0
              return ranges[mid]
            when -1
              high = mid - 1
            else
              low = mid + 1
          end
        end

        nil
      end

      def overlap?(range1, range2)
        is_numeric_range?(range1) && is_numeric_range?(range2) && (
          front_overlap?(range1, range2) ||
            rear_overlap?(range1, range2) ||
            full_overlap?(range1, range2)
        )
      end

      def front_overlap?(range1, range2)
        range1.last >= range2.first && range1.last <= range2.last
      end

      def rear_overlap?(range1, range2)
        range1.first >= range2.first && range1.first <= range2.last
      end

      # range1 entirely contains range2
      def full_overlap?(range1, range2)
        range1.first <= range2.first && range1.last >= range2.last
      end

      # range2 entirely contains range1
      def fully_overlapped_by?(range1, range2)
        range2.first <= range1.first && range1.last <= range2.last
      end

      # returns true if range1 and range2 are within 1 of each other
      def adjacent?(range1, range2)
        is_numeric_range?(range1) && is_numeric_range?(range2) &&
          (range1.last == range2.first - 1 || range2.first == range1.last + 1)
      end

      def is_numeric_range?(range)
        range.first.is_a?(Numeric) && range.last.is_a?(Numeric)
      end

      def flatten
        return if ranges.size <= 1

        sorted_ranges = ranges.sort do |a, b|
          if is_numeric_range?(a) && is_numeric_range?(b)
            a.first <=> b.first
          else
            1
          end
        end

        new_ranges = [sorted_ranges.first]

        sorted_ranges.each do |range|
          previous_range = new_ranges.pop

          if adjacent?(previous_range, range) || overlap?(previous_range, range)
            new_ranges.push(
              [range.first, previous_range.first].min..[range.last, previous_range.last].max
            )
          else
            new_ranges.push(previous_range)
            new_ranges.push(range)
          end
        end

        @ranges = new_ranges
      end

      def find_intersection(range1, range2)
        # range2 entirely contains range1
        if fully_overlapped_by?(range1, range2)
          range1.dup
        elsif front_overlap?(range1, range2)
          range2.first..range1.last
        elsif rear_overlap?(range1, range2)
          range1.first..range2.last
        elsif full_overlap?(range1, range2)
          [range1.first, range2.first].max..[range1.last, range2.last].min
        end
      end

      # subtracts range1 from range2 (range2 - range1)
      def find_subtraction(range1, range2)
        # case: range1 contains range2 entirely (also handles equal case)
        result = if full_overlap?(range1, range2)
          []
        # case: range1 comes in the middle
        elsif fully_overlapped_by?(range1, range2)
          [range2.first..(range1.first - 1), (range1.last + 1)..range2.last]
        # case: range1 trails
        elsif rear_overlap?(range1, range2)
          [range2.first..(range1.first - 1)]
        # case: range1 leads
        elsif front_overlap?(range1, range2)
          [(range1.last + 1)..range2.last]
        end

        result.reject { |r| r.first > r.last }
      end

    end
  end
end
