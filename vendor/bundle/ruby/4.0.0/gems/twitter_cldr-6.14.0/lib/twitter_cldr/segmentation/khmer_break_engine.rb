# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'
require 'forwardable'

module TwitterCldr
  module Segmentation

    # https://github.com/unicode-org/icu/blob/release-65-1/icu4j/main/classes/core/src/com/ibm/icu/text/KhmerBreakEngine.java
    class KhmerBreakEngine

      include Singleton
      extend Forwardable

      def_delegators :engine, :each_boundary

      def self.word_set
        @word_set ||= begin
          uset = TwitterCldr::Shared::UnicodeSet.new
          uset.apply_pattern('[[:Khmer:]&[:Line_Break=SA:]]')
          uset.to_set
        end
      end

      private

      # All Brahmic scripts (including Khmer) can make use of the same break
      # logic, so we use composition here and defer to the Brahmic break engine.
      def engine
        @engine ||= BrahmicBreakEngine.new(
          # How many words in a row are "good enough"?
          lookahead: 3,

          # Will not combine a non-word with a preceding dictionary word longer than this
          root_combine_threshold: 3,

          # Will not combine a non-word that shares at least this much prefix with a
          # dictionary word with a preceding word
          prefix_combine_threshold: 3,

          # Minimum word size
          min_word: 4,

          # Minimum number of characters for two words (same as min_word for Khmer)
          min_word_span: 4,

          word_set: self.class.word_set,
          mark_set: mark_set,
          end_word_set: end_word_set,
          begin_word_set: begin_word_set,
          dictionary: Dictionary.khmer,
          advance_past_suffix: -> (*) do
            0  # not applicable to Khmer
          end
        )
      end

      def mark_set
        @mark_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Khmer:]&[:Line_Break=SA:]&[:M:]]')
          set.add(0x0020)
        end
      end

      def end_word_set
        @end_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_list(self.class.word_set)
          set.subtract(0x17D2) # KHMER SIGN COENG that combines some characters
        end
      end

      def begin_word_set
        @begin_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_range(0x1780..0x17B3)
        end
      end

    end
  end
end
