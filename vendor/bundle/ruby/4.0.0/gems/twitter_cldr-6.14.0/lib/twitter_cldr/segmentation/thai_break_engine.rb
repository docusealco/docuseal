# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'
require 'forwardable'

module TwitterCldr
  module Segmentation

    # See: https://github.com/unicode-org/icu/blob/release-65-1/icu4j/main/classes/core/src/com/ibm/icu/text/ThaiBreakEngine.java
    class ThaiBreakEngine

      include Singleton
      extend Forwardable

      def_delegators :engine, :each_boundary

      def self.word_set
        @word_set ||= begin
          uset = TwitterCldr::Shared::UnicodeSet.new
          uset.apply_pattern('[[:Thai:]&[:Line_Break=SA:]]')
          uset.to_set
        end
      end

      # ellision character
      THAI_PAIYANNOI = 0x0E2F

      # repeat character
      THAI_MAIYAMOK = 0x0E46

      def each_boundary(*args, &block)
        engine.each_boundary(*args, &block)
      end

      private

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

          # Minimum number of characters for two words (min_word * 2)
          min_word_span: 4,

          word_set: self.class.word_set,
          mark_set: mark_set,
          end_word_set: end_word_set,
          begin_word_set: begin_word_set,
          dictionary: Dictionary.thai,
          advance_past_suffix: -> (*args) do
            advance_past_suffix(*args)
          end
        )
      end

      def advance_past_suffix(cursor, end_pos, state)
        suffix_length = 0

        if cursor.position < end_pos && state.word_length > 0
          uc = cursor.codepoint

          candidates = state.words[state.words_found].candidates(
            cursor, engine.dictionary, end_pos
          )

          if candidates <= 0 && suffix_set.include?(uc)
            if uc == THAI_PAIYANNOI
              unless suffix_set.include?(cursor.previous)
                # skip over previous end and PAIYANNOI
                cursor.advance(2)
                suffix_length += 1
                uc = cursor.codepoint
              else
                # restore prior position
                cursor.advance
              end
            end

            if uc == THAI_MAIYAMOK
              if cursor.previous != THAI_MAIYAMOK
                # skip over previous end and MAIYAMOK
                cursor.advance(2)
                suffix_length += 1
              else
                # restore prior position
                cursor.advance
              end
            end
          else
            cursor.position = state.current + state.word_length
          end
        end

        suffix_length
      end

      def mark_set
        @mark_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.apply_pattern('[[:Thai:]&[:Line_Break=SA:]&[:M:]]')
          set.add(0x0020)
        end
      end

      def end_word_set
        @end_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_list(self.class.word_set)
          set.subtract(0x0E31)  # MAI HAN-AKAT
          set.subtract_range(0x0E40..0x0E44)  # SARA E through SARA AI MAIMALAI
        end
      end

      def begin_word_set
        @begin_word_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add_range(0x0E01..0x0E2E)  # KO KAI through HO NOKHUK
          set.add_range(0x0E40..0x0E44)  # SARA E through SARA AI MAIMALAI
        end
      end

      def suffix_set
        @suffix_set ||= TwitterCldr::Shared::UnicodeSet.new.tap do |set|
          set.add(THAI_PAIYANNOI)
          set.add(THAI_MAIYAMOK)
        end
      end

    end
  end
end
