# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers
    class PatternTokenizer

      attr_reader :data_reader, :tokenizer

      def initialize(data_reader, tokenizer)
        @data_reader = data_reader
        @tokenizer = tokenizer
      end

      def tokenize(pattern)
        tokenizer.tokenize(expand(pattern))
      end

      private

      def expand(pattern)
        if pattern.is_a?(Symbol)
          # symbols mean another path was given
          path = pattern.to_s.split(".").map(&:to_sym)
          data = data_reader.pattern_at_path(path)
          next_pattern = data.is_a?(Hash) ? data[:pattern] : data
          expand_pattern(next_pattern)
        elsif pattern.is_a?(Hash)
          pattern.inject({}) do |ret, (key, val)|
            ret[key] = expand(val)
            ret
          end
        else
          pattern
        end
      end

    end
  end
end