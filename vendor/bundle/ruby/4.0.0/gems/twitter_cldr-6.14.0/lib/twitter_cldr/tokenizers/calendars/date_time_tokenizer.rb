# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class DateTimeTokenizer

      class << self
        def tokenizer
          @tokenizer ||= Tokenizer.new([
            TokenRecognizer.new(:date, /\{\{date\}\}/),
            TokenRecognizer.new(:time, /\{\{time\}\}/),
            TokenRecognizer.new(:plaintext, /'.*'/),
            TokenRecognizer.new(:plaintext, //)
          ])
        end
      end

      attr_reader :data_reader

      def initialize(data_reader)
        @data_reader = data_reader
      end

      def tokenize(pattern)
        expand_tokens(
          PatternTokenizer.new(data_reader, tokenizer).tokenize(pattern)
        )
      end

      # Tokenizes mixed date and time pattern strings,
      # used to tokenize the additional date format patterns.
      def full_tokenize(pattern)
        PatternTokenizer.new(data_reader, full_tokenizer).tokenize(pattern)
      end

      protected

      def expand_tokens(tokens)
        tokens.inject([]) do |ret, token|
          ret + case token.type
            when :date
              expand_date(token)
            when :time
              expand_time(token)
            else
              [token]
          end
        end
      end

      def expand_date(token)
        date_reader = data_reader.date_reader
        date_reader.tokenizer.tokenize(date_reader.pattern)
      end

      def expand_time(token)
        time_reader = data_reader.time_reader
        time_reader.tokenizer.tokenize(time_reader.pattern)
      end

      def full_tokenizer
        @@full_tokenizer ||= begin
          new_tok = Tokenizer.union(
            data_reader.date_reader.tokenizer.tokenizer,
            data_reader.time_reader.tokenizer.tokenizer
          ) do |recognizer|
            recognizer.token_type != :plaintext
          end

          new_tok.recognizers << TokenRecognizer.new(:plaintext, //)
          new_tok
        end
      end

      def tokenizer
        self.class.tokenizer
      end

    end
  end
end
