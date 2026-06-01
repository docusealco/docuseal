# -*- frozen_string_literal: true -*-
#
#--
# geom2d - 2D Geometric Objects and Algorithms
# Copyright (C) 2018-2023 Thomas Leitner <t_leitner@gmx.at>
#
# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
#++

module Geom2D
  module Utils

    # A list that keeps its items sorted. Currently only used by
    # Geom2D::Algorithms::PolygonOperation and therefore with special methods for the latter.
    class SortedList

      include Enumerable

      # Creates a new SortedList using the +comparator+ or the given block as compare function.
      #
      # The comparator has to respond to +call(a, b)+ where +a+ is the value to be inserted and +b+
      # is the value to which it is compared. The return value should be +true+ if the value +a+
      # should be inserted before +b+, i.e. at the position of +b+.
      def initialize(comparator = nil, &block)
        @list = []
        @comparator = comparator || block
      end

      # Returns +true+ if the list is empty?
      def empty?
        @list.empty?
      end

      # Returns the last value in the list.
      def last
        @list.last
      end

      # Yields each value in sorted order.
      #
      # If no block is given, an enumerator is returned.
      def each(&block) # :yield: value
        @list.each(&block)
      end

      # Inserts the value and returns self.
      def push(value)
        insert(value)
        self
      end

      # Inserts a new value into the list (at a position decided by the compare function) and
      # returns the previous-previous, previous and next values.
      def insert(value)
        i = @list.bsearch_index {|el| @comparator.call(value, el) } || @list.size
        @list.insert(i, value)
        [(i <= 1 ? nil : @list[i - 2]), (i == 0 ? nil : @list[i - 1]), @list[i + 1]]
      end

      # Deletes the given value and returns the previous and next values.
      def delete(value)
        i = @list.index(value)
        result = [(i == 0 ? nil : @list[i - 1]), @list[i + 1]]
        @list.delete_at(i)
        result
      end

      # Clears the list.
      def clear
        @list.clear
      end

      # Removes the top value from the list and returns it.
      def pop
        @list.pop
      end

      def inspect # :nodoc:
        "#<#{self.class.name}:0x#{object_id.to_s(16).rjust(0.size * 2, '0')} #{to_a}>"
      end

    end

  end
end
