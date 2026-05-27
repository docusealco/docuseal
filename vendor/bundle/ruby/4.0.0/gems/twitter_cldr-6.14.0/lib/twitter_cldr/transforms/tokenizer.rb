# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms

    class Tokenizer
      def tokenize(rule_text)
        tokenizer.tokenize(rule_text)
      end

      private

      def tokenizer
        TwitterCldr::Tokenizers::Tokenizer.new(recognizers)
      end

      def recognizers
        @recognizers ||= [
          TwitterCldr::Tokenizers::TokenRecognizer.new(:capture, /\$[\d]+/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:variable, /\$[\w]+/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:doubled_quote, /''/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:quoted_string, /'[^']*'/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:direction, /[<>]{1,2}/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:before_context, /[{]/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:after_context, /[}]/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:cursor, /\|/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:unicode_char, /\\u[a-fA-F0-9]{1,6}/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:unicode_char, /\\u\{[a-fA-F0-9]{1,6}\}/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:escaped_char, /\\./),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:escaped_backslash, /\\\\/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:equals, /=/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:semicolon, /;/),
          TwitterCldr::Tokenizers::TokenRecognizer.new(:string, /[^ ]{1}/)
        ]
      end
    end

  end
end
