# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class PossibleWordList

      attr_reader :length, :items

      def initialize(length)
        @items = Array.new(length) { PossibleWord.new }
        @length = length
      end

      def [](idx)
        items[idx % length]
      end

    end
  end
end
