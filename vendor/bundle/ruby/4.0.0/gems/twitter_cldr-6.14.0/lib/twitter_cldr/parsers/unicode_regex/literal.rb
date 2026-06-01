# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers
    class UnicodeRegexParser
      class Literal < Component

        attr_reader :text

        # ord is good enough (don't need unpack) because ASCII chars
        # have the same numbers as their unicode equivalents
        def self.ordinalize(char)
          if char.respond_to?(:ord)
            char.ord
          else
            char[0]
          end
        end

        SPECIAL_CHARACTERS = {
          "s" => [32],  # space
          "t" => [9],   # tab
          "r" => [13],  # carriage return
          "n" => [10],  # newline
          "f" => [12],  # form feed
          "d" => ("0".."9").to_a.map { |c| ordinalize(c) },
          "w" => (("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a + ["_"]).map { |c| ordinalize(c) }
        }

        def initialize(text)
          @text = text
        end

        def to_regexp_str
          text
        end

        def to_set
          if text =~ /^\\/
            special_char = text[1..-1]

            if SPECIAL_CHARACTERS.include?(special_char.downcase)
              set_for_special_char(special_char)
            else
              TwitterCldr::Utils::RangeSet.from_array([
                self.class.ordinalize(special_char)
              ])
            end
          else
            TwitterCldr::Utils::RangeSet.from_array([
              self.class.ordinalize(text)
            ])
          end
        end

        def to_s
          text
        end

        def type
          :literal
        end

        private

        def set_for_special_char(char)
          special_char_set_cache[char] ||= begin
            chars = TwitterCldr::Utils::RangeSet.from_array(
              SPECIAL_CHARACTERS[char.downcase]
            )

            if char.upcase == char
              TwitterCldr::Shared::UnicodeRegex.valid_regexp_chars.subtract(chars)
            else
              chars
            end
          end
        end

        def special_char_set_cache
          @@special_char_set_cache ||= {}
        end

      end

    end
  end
end
