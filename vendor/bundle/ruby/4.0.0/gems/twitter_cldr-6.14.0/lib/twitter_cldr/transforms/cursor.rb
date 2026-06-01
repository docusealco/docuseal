# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class Cursor
      attr_reader :text, :position

      def initialize(text)
        set_text(text)
        reset_position
      end

      def advance(amount = 1)
        @position += amount
      end

      def set_text(new_text)
        @text = new_text
      end

      def reset_position
        @position = 0
      end

      def eos?
        position >= text.size
      end

      def index_values
        text[position].bytes
      end
    end

  end
end
