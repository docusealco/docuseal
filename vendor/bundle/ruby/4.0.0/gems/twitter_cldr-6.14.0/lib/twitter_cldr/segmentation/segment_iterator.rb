# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class SegmentIterator
      attr_reader :rule_set

      def initialize(rule_set)
        @rule_set = rule_set
      end

      def each_segment(str)
        return to_enum(__method__, str) unless block_given?

        each_boundary(str).each_cons(2) do |start, stop|
          yield str[start...stop], start, stop
        end
      end

      def each_boundary(str, &block)
        return to_enum(__method__, str) unless block_given?

        # implicit start of text boundary
        yield 0

        cursor = create_cursor(str)
        rule_set.each_boundary(cursor, &block)
      end

      private

      def create_cursor(str)
        Cursor.new(str)
      end
    end
  end
end
