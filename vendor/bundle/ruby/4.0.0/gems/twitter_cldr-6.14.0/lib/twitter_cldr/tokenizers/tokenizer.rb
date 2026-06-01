# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Tokenizers

    class TokenRecognizer

      attr_reader :token_type, :regex, :content, :cleaner

      def initialize(token_type, regex, content = nil, &block)
        @token_type = token_type
        @regex = regex
        @content = content
        @cleaner = block
      end

      def recognizes?(text)
        !!(text =~ regex)
      end

      def clean(val)
        if cleaner
          cleaner.call(val)
        else
          val
        end
      end

    end

    class Tokenizer

      attr_reader :recognizers, :custom_splitter, :remove_empty_entries

      def self.union(*tokenizers)
        recognizers = tokenizers.inject([]) do |ret, tokenizer|
          ret + tokenizer.recognizers.inject([]) do |recog_ret, recognizer|
            if (block_given? && yield(recognizer)) || !block_given?
              recog_ret << recognizer
            end
            recog_ret
          end
        end

        splitter = if tokenizers.all?(&:custom_splitter)
          Regexp.compile(
            tokenizers.map do |tokenizer|
              tokenizer.custom_splitter.source
            end.join("|")
          )
        end

        new(recognizers, splitter)
      end

      def initialize(recognizers, splitter = nil, remove_empty_entries = true)
        @recognizers = recognizers
        @custom_splitter = splitter
        @remove_empty_entries = remove_empty_entries
      end

      def recognizer_at(token_type)
        recognizers.find { |r| r.token_type == token_type }
      end

      def insert_before(token_type, *new_recognizers)
        idx = recognizers.find_index { |rec| rec.token_type == token_type }
        recognizers.insert(idx, *new_recognizers)
        clear_splitter
        nil
      end

      def tokenize(text)
        text.split(splitter).inject([]) do |ret, token_text|
          recognizer = recognizers.find do |recognizer|
            recognizer.recognizes?(token_text)
          end

          if recognizer
            cleaned_text = recognizer.clean(token_text)

            if (remove_empty_entries && cleaned_text.size > 0) || !remove_empty_entries
              ret << Token.new(
                value: cleaned_text,
                type: recognizer.token_type
              )
            end
          end

          ret
        end
      end

      private

      def splitter
        @splitter ||= (@custom_splitter || begin
          sources = recognizers.map { |rec| rec.regex.source }
          Regexp.new("(" + sources.join("|") + ")")
        end)
      end

      def clear_splitter
        @splitter = nil
      end

    end
  end
end
