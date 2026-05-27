# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'set'

module TwitterCldr
  module Segmentation
    class DeormalizedStringError < StandardError; end

    class WordIterator < SegmentIterator
      DICTIONARY_BREAK_ENGINES = [
        CjBreakEngine,
        KoreanBreakEngine,
        BurmeseBreakEngine,
        KhmerBreakEngine,
        LaoBreakEngine,
        ThaiBreakEngine
      ]

      def each_boundary(str, &block)
        return to_enum(__method__, str) unless block_given?

        # Rather than put a bunch of duplicate logic in
        # each_boundary_helper to make sure we don't yield the same
        # boundary twice, we wrap it in this additional de-duping
        # enumerator and call it a day.
        last_boundary = nil

        each_boundary_helper(str) do |boundary|
          yield boundary if boundary != last_boundary
          last_boundary = boundary
        end
      end

      private

      def each_boundary_helper(str, &block)
        # Set up two independent cursors so the algorithm can iterate
        # over those portions of the input string that require a
        # dictionary-based break iterator independently from those that
        # only need the normal, rule-based break iterator. Cursors
        # hold references to the input text and a list of all the
        # corresponding Unicode codepoints, meaning they are fairly
        # expensive to create. The duplication below should only
        # produce a shallow copy however. The text and codepoint list
        # are not duplicated, but the cursor's integer position can
        # be varied independently.
        dict_cursor = create_cursor(str)
        rule_cursor = dict_cursor.dup

        # implicit start of text boundary
        yield 0

        until dict_cursor.eos? || rule_cursor.eos?
          # We use a regex to identify the beginnings of potential runs
          # of dictionary characters. This regex was benchmarked and
          # found to be pretty fast, but could become a bottleneck if
          # other parts of the algorithm are improved in the future.
          m = dictionary_re.match(dict_cursor.text, dict_cursor.position)
          break unless m

          dict_cursor.position = m.begin(0)
          dict_break_engine = dictionary_break_engine_for(dict_cursor.codepoint)

          # It's possible to encounter a dictionary character that can't
          # be handled by any of the dictionary-based break engines
          # because it's too short to make up an actual word. The
          # break engine will simply yield no breaks in such a case, which
          # we test for below by peeking for the first boundary value and
          # rescuing a StopIteration error. Since the run of dictionary
          # characters may be arbitrarily long, peeking should be more
          # performant than attempting to calculate all the boundary
          # positions for the run at once.
          #
          # It should be noted that, despite our best efforts here in
          # WordIterator, certain dictionary-based break engines (eg.
          # CjBreakEngine) cannot yield word boundaries without first
          # examining the entire run of dictionary characters. In practice
          # this shouldn't be too big an issue, since Chinese text often
          # contains punctuation that should limit the average run length.
          dict_enum = dict_break_engine.each_boundary(dict_cursor)

          dict_boundary = begin
            dict_enum.peek
          rescue StopIteration
            nil
          end

          # If a dictionary boundary was found, attempt to use the rule-based
          # break iterator to find breaks in the text immediately before it.
          # Otherwise, since none of the dictionary-based break engines could
          # find any boundaries in the current run, we advance the dictionary
          # cursor in an attempt to find the next dictionary boundary. Doing
          # so effectively causes the algorithm to fall back to the rule-based
          # break engine.
          if dict_boundary
            # Only use the rule-based break engine if there are characters to
            # process.
            if rule_cursor.position < m.begin(0)
              rule_set.each_boundary(rule_cursor, m.begin(0), &block)
            end

            # Yield all the dictionary breaks from the enum. We can't use .each
            # here because that will restart the iteration. Ruby's loop
            # construct automatically rescues StopIteration.
            loop do
              yield dict_enum.next
            end

            # We've reached the end of a dictionary character run, so yield
            # the end of text boundary.
            yield dict_cursor.position

            # These should be the same after a successful dictionary run, i.e.
            # they should both be positioned at the end of the current rule-based
            # and dictionary-based portions of the run, ready for the next one.
            rule_cursor.position = dict_cursor.position
          else
            dict_cursor.advance
          end
        end

        # Find boundaries in the straggler, non-dictionary run at the end of
        # the input text.
        unless rule_cursor.eos?
          rule_set.each_boundary(rule_cursor, &block)
        end

        # implicit end of text boundary
        yield rule_cursor.length
      end

      # all dictionary characters, i.e. characters that must be handled
      # by one of the dictionary-based break engines
      def dictionary_set
        @@dictionary_set ||= Set.new.tap do |set|
          DICTIONARY_BREAK_ENGINES.each do |break_engine|
            set.merge(break_engine.word_set)
          end
        end
      end

      def dictionary_break_engine_for(codepoint)
        codepoint_to_engine_cache[codepoint] ||= begin
          engine = DICTIONARY_BREAK_ENGINES.find do |break_engine|
            break_engine.word_set.include?(codepoint)
          end

          (engine || UnhandledBreakEngine).instance
        end
      end

      def dictionary_re
        @@dictionary_re ||= begin
          ranges = TwitterCldr::Utils::RangeSet.from_array(dictionary_set).ranges.map do |r|
            "\\u{#{r.first.to_s(16)}}-\\u{#{r.last.to_s(16)}}"
          end

          /[#{ranges.join}]/
        end
      end

      def codepoint_to_engine_cache
        @@codepoint_to_engine_cache ||= {}
      end
    end
  end
end
