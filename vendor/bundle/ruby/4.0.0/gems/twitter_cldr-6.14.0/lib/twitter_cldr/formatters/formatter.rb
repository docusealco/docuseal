# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class Formatter

      attr_reader :data_reader

      def initialize(data_reader)
        @data_reader = data_reader
      end

      def format(tokens, obj, options = {})
        tokens.each_with_index.inject("") do |ret, (token, index)|
          method_sym = :"format_#{token.type}"
          ret << send(method_sym, token, index, obj, options)
        end
      end

      protected

      def format_plaintext(token, index, obj, options)
        token.value.gsub(/'([^']+)'/, '\1') # remove single-quote escaping for "real" characters
      end

    end
  end
end
