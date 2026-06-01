# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Shared
    class UnicodeRegex

      class << self

        def compile(str, modifiers = "", symbol_table = nil)
          new(
            parser.parse(tokenizer.tokenize(str), {
              symbol_table: symbol_table
            }), modifiers
          )
        end

        # All unicode characters
        def all_unicode
          @all_unicode ||= TwitterCldr::Utils::RangeSet.new(
            [0..0x10FFFF]
          )
        end

        # A few <control> characters (i.e. 2..7) and public/private surrogates (i.e. 55296..57343).
        # These don't play nicely with Ruby's regular expression engine, and I think we
        # can safely disregard them.
        def invalid_regexp_chars
          @invalid_regexp_chars ||= TwitterCldr::Utils::RangeSet.new(
            [2..7, 55296..57343]
          )
        end

        def valid_regexp_chars
          @valid_regexp_chars ||= all_unicode.subtract(invalid_regexp_chars)
        end

        private

        def tokenizer
          @tokenizer ||= TwitterCldr::Tokenizers::UnicodeRegexTokenizer.new
        end

        def parser
          @parser ||= TwitterCldr::Parsers::UnicodeRegexParser.new
        end

      end

      extend Forwardable
      def_delegator :to_regexp, :match
      def_delegator :to_regexp, :=~

      attr_reader :elements, :modifiers

      def initialize(elements, modifiers = nil)
        @elements = elements
        @modifiers = modifiers
      end

      def to_regexp
        @regexp ||= Regexp.new(to_regexp_str, modifier_union)
      end

      def to_regexp_str
        @regexp_str ||= elements.map(&:to_regexp_str).join
      end

      def to_s
        @elements.inject('') do |ret, element|
          ret + element.to_s
        end
      end

      private

      def modifier_union
        @modifier_union ||=
          (modifiers || '').each_char.inject(0) do |ret, modifier_char|
            ret | case modifier_char
              when 'm'
                Regexp::MULTILINE
              when 'i'
                Regexp::IGNORECASE
              when 'x'
                Regexp::EXTENDED
              when 'n'
                Regexp::NOENCODING
              else
                0
            end
          end
      end

    end
  end
end
