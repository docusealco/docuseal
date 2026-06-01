# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Parsers

    # This is really just a thin layer on top of Hash.
    # Nice to have it abstracted in case we have to add custom behavior.
    class SymbolTable

      attr_reader :symbols

      def initialize(symbols = {})
        @symbols = symbols
      end

      def fetch(symbol)
        symbols.fetch(symbol)
      end

      def add(symbol, value)
        symbols[symbol] = value
      end

    end

  end
end
