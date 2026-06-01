# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'
require 'forwardable'

module TwitterCldr
  module Segmentation

    # See: https://github.com/unicode-org/icu/blob/release-65-1/icu4j/main/classes/core/src/com/ibm/icu/text/LaoBreakEngine.java
    class LaoBreakEngine

      include Singleton
      extend Forwardable

      def_delegators :engine, :each_boundary

      def self.word_set
        @word_set ||= begin
          uset = TwitterCldr::Shared::UnicodeSet.new
          uset.apply_pattern('[[:Laoo:]&[:Line_Break=SA:]]')
          uset.to_set
        end
      end

      private

      # All Brahmic scripts (including Lao) can make use of the same break
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
          min_word: 2,

          # Minimum number of characters for two words (same as min_word for Lao)
          min_word_span: 2,

          word_set: self.class.word_set,
          mark_set: mark_set,
          end_word_set: end_word_set,
          begin_word_set: begin_word_set,
          dictionary: Dictionary.lao,
          advance_past_suffix: -> (*) do
            0  # not applicable to Lao
          end
        )
      end

      def mark_set
        @mark_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Laoo:]&[:Line_Break=SA:]&[:M:]]')
          set.add(0x0020)
        end
      end

      def end_word_set
        @end_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_list(self.class.word_set)
          set.subtract_range(0x0EC0..0x0EC4) # prefix vowels
        end
      end

      def begin_word_set
        @begin_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_range(0x0E81..0x0EAE)  # basic consonants (including holes for corresponding Thai characters)
          set.add_range(0x0EDC..0x0EDD)  # digraph consonants (no Thai equivalent)
          set.add_range(0x0EC0..0x0EC4)  # prefix vowels
        end
      end

    end
  end
end
