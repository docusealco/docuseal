# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class TimespanTokenizer

      attr_reader :data_reader

      def initialize(data_reader)
        @data_reader = data_reader
      end

      def tokenize(pattern)
        PatternTokenizer.new(data_reader, tokenizer).tokenize(pattern)
      end

      protected

      def tokenizer
        @tokenizer ||= Tokenizer.new([
          TokenRecognizer.new(:pattern, /\{?[0?#,\.]+\}?/),
          TokenRecognizer.new(:plaintext, //)
        ], /([^0*#,\.\{\}]*)(\{?[0#,\.]+\}?)([^0*#,\.\{\}]*)$/)
      end

    end
  end
end