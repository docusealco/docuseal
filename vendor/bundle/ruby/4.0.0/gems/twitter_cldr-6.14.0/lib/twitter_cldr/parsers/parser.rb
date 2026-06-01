# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers

    class UnexpectedTokenError < StandardError; end

    # base class, not meant to be instantiated
    class Parser

      def parse(tokens, options = {})
        @tokens = tokens
        reset
        do_parse(options)
      end

      def reset
        @token_index = 0
      end

      def eof?
        @token_index >= @tokens.size
      end

      private

      def next_token(type)
        unless current_token.type == type
          raise UnexpectedTokenError.new("Unexpected token #{current_token.type} \"#{current_token.value}\"")
        end

        @token_index += 1

        while current_token && empty?(current_token)
          @token_index += 1
        end

        current_token
      end

      def empty?(token)
        token.type == :plaintext && token.value == ""
      end

      def current_token
        @tokens[@token_index]
      end
    end

  end
end
