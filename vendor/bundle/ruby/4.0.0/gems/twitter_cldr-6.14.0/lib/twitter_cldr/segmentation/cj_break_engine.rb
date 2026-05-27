# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Segmentation
    class CjBreakEngine < DictionaryBreakEngine

      include Singleton

      # magic number pulled from ICU's source code, presumably slightly longer
      # than the longest Chinese/Japanese/Korean word
      MAX_WORD_SIZE = 20

      # magic number pulled from ICU's source code
      MAX_SNLP = 255

      # the equivalent of Java's Integer.MAX_VALUE
      LARGE_NUMBER = 0xFFFFFFFF

      MAX_KATAKANA_LENGTH = 8
      MAX_KATAKANA_GROUP_LENGTH = 20
      KATAKANA_COSTS = [8192, 984, 408, 240, 204, 252, 300, 372, 480].freeze
      MAX_KATAKANA_COST = 8192

      def self.word_set
        @word_set ||= begin
          uset = TwitterCldr::Shared::UnicodeSet.new
          uset.apply_pattern('[:Han:]')
          uset.apply_pattern('[[:Katakana:]\uff9e\uff9f]')
          uset.apply_pattern('[:Hiragana:]')
          uset.add(0xFF70)  # HALFWIDTH KATAKANA-HIRAGANA PROLONGED SOUND MARK
          uset.add(0x30FC)  # KATAKANA-HIRAGANA PROLONGED SOUND MARK
          uset.to_set
        end
      end

      private

      def word_set
        self.class.word_set
      end

      def divide_up_dictionary_range(cursor, end_pos, &block)
        return to_enum(__method__, cursor, end_pos) unless block_given?

        input_length = end_pos - cursor.position
        best_snlp = Array.new(input_length + 1) { LARGE_NUMBER }
        prev = Array.new(input_length + 1) { -1 }

        best_snlp[0] = 0
        start_pos = cursor.position
        is_prev_katakana = false

        until cursor.position >= end_pos
          idx = cursor.position - start_pos

          if best_snlp[idx] == LARGE_NUMBER
            cursor.advance
            next
          end

          max_search_length = if cursor.position + MAX_WORD_SIZE < end_pos
            MAX_WORD_SIZE
          else
            end_pos - cursor.position
          end

          count, values, lengths, _ = dictionary.matches(
            cursor, max_search_length, max_search_length
          )

          if (count == 0 || lengths[0] != 1) && !hangul_word_set.include?(cursor.codepoint)
            values[count] = MAX_SNLP
            lengths[count] = 1
            count += 1
          end

          count.times do |j|
            new_snlp = best_snlp[idx] + values[j]

            if new_snlp < best_snlp[lengths[j] + idx]
              best_snlp[lengths[j] + idx] = new_snlp
              prev[lengths[j] + idx] = idx
            end
          end

          # In Japanese, single-character Katakana words are pretty rare.
          # Accordingly, we apply the following heuristic: any continuous
          # run of Katakana characters is considered a candidate word with
          # a default cost specified in the katakanaCost table according
          # to its length.
          is_katakana = is_katakana?(cursor.codepoint)

          if !is_prev_katakana && is_katakana
            j = idx + 1
            cursor.advance

            while cursor.position < end_pos && (j - idx) < MAX_KATAKANA_GROUP_LENGTH && is_katakana?(cursor.codepoint)
              cursor.advance
              j += 1
            end

            if (j - idx) < MAX_KATAKANA_GROUP_LENGTH
              new_snlp = best_snlp[idx] + get_katakana_cost(j - idx)

              if new_snlp < best_snlp[j]
                best_snlp[j] = new_snlp
                prev[j] = idx
              end
            end
          end

          is_prev_katakana = is_katakana

          cursor.advance
        end

        t_boundary = []

        if best_snlp[input_length] == LARGE_NUMBER
          t_boundary << end_pos
        else
          idx = end_pos - start_pos

          while idx > 0
            t_boundary << idx + start_pos
            idx = prev[idx]
          end
        end

        t_boundary.reverse_each(&block)
      end

      private

      def hangul_word_set
        @@hangul_word_set ||= KoreanBreakEngine.word_set
      end

      def is_katakana?(codepoint)
        (codepoint >= 0x30A1 && codepoint <= 0x30FE && codepoint != 0x30FB) ||
          (codepoint >= 0xFF66 && codepoint <= 0xFF9F)
      end

      def get_katakana_cost(word_length)
        if word_length > MAX_KATAKANA_LENGTH
          MAX_KATAKANA_COST
        else
          KATAKANA_COSTS[word_length]
        end
      end

      def dictionary
        @dictionary ||= Dictionary.cj
      end

    end
  end
end
