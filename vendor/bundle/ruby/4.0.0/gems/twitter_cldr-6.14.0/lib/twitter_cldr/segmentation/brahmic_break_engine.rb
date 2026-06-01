# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation
    # Base class break engine for languages derived from the Brahmic script,
    # i.e. Lao, Thai, Khmer, and Burmese.
    #
    # This class is based on duplicated code found in ICU's BurmeseBreakEngine
    # and friends, which all make use of the same break logic.
    class BrahmicBreakEngine < DictionaryBreakEngine

      # ICU keeps track of all these variables inline, but since we've done a
      # bit of method separating (see below), it's too ugly to pass all of
      # them around as arguments. Instead we encapsulate them all in this
      # handy state object.
      class EngineState
        attr_accessor :current
        attr_reader :words
        attr_accessor :words_found, :word_length

        def initialize(options = {})
          @current = options.fetch(:current, 0)
          @words = options.fetch(:words)
          @words_found = options.fetch(:words_found, 0)
          @word_length = options.fetch(:word_length, 0)
        end
      end

      attr_reader :lookahead, :root_combine_threshold
      attr_reader :prefix_combine_threshold, :min_word, :min_word_span
      attr_reader :word_set, :mark_set, :end_word_set, :begin_word_set
      attr_reader :dictionary, :advance_past_suffix

      def initialize(options = {})
        @lookahead = options.fetch(:lookahead)
        @root_combine_threshold = options.fetch(:root_combine_threshold)
        @prefix_combine_threshold = options.fetch(:prefix_combine_threshold)
        @min_word = options.fetch(:min_word)
        @min_word_span = options.fetch(:min_word_span)

        @word_set = options.fetch(:word_set)
        @mark_set = options.fetch(:mark_set)
        @end_word_set = options.fetch(:end_word_set)
        @begin_word_set = options.fetch(:begin_word_set)

        @dictionary = options.fetch(:dictionary)
        @advance_past_suffix = options.fetch(:advance_past_suffix)
      end

      private

      # See: https://github.com/unicode-org/icu/blob/release-65-1/icu4j/main/classes/core/src/com/ibm/icu/text/BurmeseBreakEngine.java#L88
      def divide_up_dictionary_range(cursor, end_pos)
        return to_enum(__method__, cursor, end_pos) unless block_given?
        return if (end_pos - cursor.position) < min_word_span

        state = EngineState.new(
          cursor: cursor,
          end_pos: end_pos,
          words: PossibleWordList.new(lookahead)
        )

        while cursor.position < end_pos
          state.current = cursor.position
          state.word_length = 0

          # look for candidate words at the current position
          candidates = state.words[state.words_found].candidates(
            cursor, dictionary, end_pos
          )

          # if we found exactly one, use that
          if candidates == 1
            state.word_length = state.words[state.words_found].accept_marked(cursor)
            state.words_found += 1
          elsif candidates > 1
            mark_best_candidate(cursor, end_pos, state)
            state.word_length = state.words[state.words_found].accept_marked(cursor)
            state.words_found += 1
          end

          # We come here after having either found a word or not. We look ahead to the
          # next word. If it's not a dictionary word, we will combine it with the word we
          # just found (if there is one), but only if the preceding word does not exceed
          # the threshold. The cursor should now be positioned at the end of the word we
          # found.
          if cursor.position < end_pos && state.word_length < root_combine_threshold
            # If it is a dictionary word, do nothing. If it isn't, then if there is
            # no preceding word, or the non-word shares less than the minimum threshold
            # of characters with a dictionary word, then scan to resynchronize.
            preceeding_words = state.words[state.words_found].candidates(
              cursor, dictionary, end_pos
            )

            if preceeding_words <= 0 && (state.word_length == 0 || state.words[state.words_found].longest_prefix < prefix_combine_threshold)
              advance_to_plausible_word_boundary(cursor, end_pos, state)
            else
              # backup to where we were for next iteration
              cursor.position = state.current + state.word_length
            end
          end

          # never stop before a combining mark.
          while cursor.position < end_pos && mark_set.include?(cursor.codepoint)
            cursor.advance
            state.word_length += 1
          end

          # Look ahead for possible suffixes if a dictionary word does not follow.
          # We do this in code rather than using a rule so that the heuristic
          # resynch continues to function. For example, one of the suffix characters
          # could be a typo in the middle of a word.
          state.word_length += advance_past_suffix.call(
            cursor, end_pos, state
          )

          # Did we find a word on this iteration? If so, yield it as a boundary.
          if state.word_length > 0
            yield state.current + state.word_length
          end
        end
      end

      private

      # In ICU, this method is part of divide_up_dictionary_range. Extracted here
      # for readability.
      def advance_to_plausible_word_boundary(cursor, end_pos, state)
        remaining = end_pos - (state.current + state.word_length)
        pc = cursor.codepoint
        chars = 0

        loop do
          cursor.advance
          uc = cursor.codepoint
          chars += 1
          remaining -= 1

          break if remaining <= 0

          if end_word_set.include?(pc) && begin_word_set.include?(uc)
            # Maybe. See if it's in the dictionary.
            candidate = state.words[state.words_found + 1].candidates(cursor, dictionary, end_pos)
            cursor.position = state.current + state.word_length + chars
            break if candidate > 0
          end

          pc = uc
        end

        # bump the word count if there wasn't already one
        state.words_found += 1 if state.word_length <= 0

        # update the length with the passed-over characters
        state.word_length += chars
      end

      def mark_best_candidate(cursor, end_pos, state)
        # if there was more than one, see which one can take us forward the most words
        found_best = false

        # if we're already at the end of the range, we're done
        if cursor.position < end_pos
          loop do
            words_matched = 1

            if state.words[state.words_found + 1].candidates(cursor, dictionary, end_pos) > 0
              if words_matched < 2
                # followed by another dictionary word; mark first word as a good candidate
                state.words[state.words_found].mark_current
                words_matched = 2
              end

              # if we're already at the end of the range, we're done
              break if cursor.position >= end_pos

              # see if any of the possible second words is followed by a third word
              loop do
                # if we find a third word, stop right away
                if state.words[state.words_found + 2].candidates(cursor, dictionary, end_pos) > 0
                  state.words[state.words_found].mark_current
                  found_best = true
                  break
                end

                break unless state.words[state.words_found + 1].back_up(cursor)
              end
            end

            break unless state.words[state.words_found].back_up(cursor) && !found_best
          end
        end
      end

    end
  end
end
