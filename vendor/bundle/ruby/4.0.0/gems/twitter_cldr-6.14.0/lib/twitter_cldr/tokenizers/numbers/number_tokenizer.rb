# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class NumberTokenizer

      SPECIAL_SYMBOLS_MAP = {
        '.' => '{DOT}',
        ',' => '{COMMA}',
        '0' => '{ZERO}',
        '#' => '{POUND}',
        '¤' => '{CURRENCY}',
        '%' => '{PERCENT}',
        'E' => '{SCIENTIFIC}'
      }

      SPECIAL_SYMBOLS_REGEX = /'(?:#{SPECIAL_SYMBOLS_MAP.keys.map { |s| Regexp.escape(s) }.join('|')})'/

      INVERSE_SPECIAL_SYMBOLS_MAP = SPECIAL_SYMBOLS_MAP.invert

      INVERSE_SPECIAL_SYMBOLS_REGEX = /#{INVERSE_SPECIAL_SYMBOLS_MAP.keys.map { |s| Regexp.escape(s) }.join('|')}/

      attr_reader :data_reader

      def initialize(data_reader)
        @data_reader = data_reader
      end

      def tokenize(pattern)
        escaped_pattern = pattern.gsub(SPECIAL_SYMBOLS_REGEX) do |match|
          SPECIAL_SYMBOLS_MAP[match[1..-2]]
        end

        tokens = PatternTokenizer.new(data_reader, tokenizer).tokenize(escaped_pattern)

        tokens.each do |token|
          token.value = token.value.gsub(INVERSE_SPECIAL_SYMBOLS_REGEX) do |match|
            INVERSE_SPECIAL_SYMBOLS_MAP[match]
          end
        end

        if tokens.first.value == ""
          tokens[1..-1]
        else
          tokens
        end
      end

      private

      def tokenizer
        @tokenizer ||= Tokenizer.new([
          TokenRecognizer.new(:pattern, /[0?#,\.]+/),
          TokenRecognizer.new(:plaintext, //),
        ], /([^0*#,\.]*)([0#,\.]+)([^0*#,\.]*)$/, false)
      end

    end
  end
end
