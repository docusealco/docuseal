# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      # unicode_char, escaped_char, string, multichar_string
      # Can exist inside and outside of character classes
      class UnicodeString < Component

        attr_reader :codepoints

        def initialize(codepoints)
          @codepoints = codepoints
        end

        def to_set
          # If the number of codepoints is greater than 1, treat them as a
          # group (eg. multichar string). This is definitely a hack in that
          # it means there has to be special logic in RangeSet that deals
          # with data types that aren't true integer ranges. I can't think
          # of any other way to support multichar strings :(
          if codepoints.size > 1
            TwitterCldr::Utils::RangeSet.new([codepoints..codepoints])
          else
            TwitterCldr::Utils::RangeSet.new([codepoints.first..codepoints.first])
          end
        end

        def to_regexp_str
          array_to_regex(Array(codepoints))
        end

        def to_s
          to_regexp_str
        end

        def type
          :unicode_string
        end

      end
    end
  end
end
