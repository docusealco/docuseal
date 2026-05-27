# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    class Cursor
      attr_reader :text, :codepoints
      attr_accessor :position

      def initialize(text)
        @text = text
        @codepoints = text.codepoints
        reset
      end

      def advance(amount = 1)
        if @position + amount > text.size
          @position = text.size
        else
          @position += amount
        end
      end

      def reset
        @position = 0
      end

      def eos?
        position >= text.size
      end

      def codepoint(pos = @position)
        codepoints[pos]
      end

      def length
        text.length
      end
    end
  end
end
