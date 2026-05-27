# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class UnicodeRegexTokenizer

      extend Forwardable
      def_delegator :tokenizer, :insert_before

      def tokenize(pattern)
        tokenizer.tokenize(pattern)
      end

      private

      def tokenizer
        @tokenizer ||= begin
          recognizers = [
            # The variable name can contain letters and digits, but must start with a letter.
            TokenRecognizer.new(:variable, /\$\w[\w\d]*/),
            TokenRecognizer.new(:character_set, /\[:[\w\s=]+:\]|\\p\{[\w\s=]+\}/),  # [:Lu:] or \p{Lu} or \p{Sentence_Break=CF}
            TokenRecognizer.new(:negated_character_set, /\[:\^[\w\s=]+:\]|\\P\{[\w\s=]+\}/),  #[:^Lu:] or \P{Lu}
            TokenRecognizer.new(:unicode_char, /\\u\{?[a-fA-F0-9]{1,6}\}?/),
            TokenRecognizer.new(:multichar_string, /\{\w+\}/u),

            TokenRecognizer.new(:escaped_character, /\\./),
            TokenRecognizer.new(:negate, /\^/),
            TokenRecognizer.new(:ampersand, /&/),
            TokenRecognizer.new(:pipe, /\|/),
            TokenRecognizer.new(:dash, /-/),

            # stuff that shouldn't be converted to codepoints
            TokenRecognizer.new(:special_char, /\{\d,?\d?\}|[$?:{}()*+\.,\/\\]/),

            TokenRecognizer.new(:open_bracket, /\[/),
            TokenRecognizer.new(:close_bracket, /\]/),

            TokenRecognizer.new(:string, //u) do |val|
              val == " " ? val : val.strip
            end
          ]

          Tokenizer.new(recognizers)
        end
      end

    end
  end
end
