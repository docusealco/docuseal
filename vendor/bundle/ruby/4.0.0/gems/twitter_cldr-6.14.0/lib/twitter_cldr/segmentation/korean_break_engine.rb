# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class KoreanBreakEngine < CjBreakEngine

      include Singleton

      def self.word_set
        @word_set ||= begin
          uset = TwitterCldr::Shared::UnicodeSet.new
          uset.add_range(0xAC00..0xD7A3)
          uset.to_set
        end
      end

      private

      def word_set
        self.class.word_set
      end

    end
  end
end
