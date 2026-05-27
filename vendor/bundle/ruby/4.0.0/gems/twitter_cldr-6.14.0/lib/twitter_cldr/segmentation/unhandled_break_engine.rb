# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class UnhandledBreakEngine

      include Singleton

      def each_boundary(cursor, &block)
        return to_enum(__method__, cursor) unless block_given?
        cursor.advance
      end

    end
  end
end
