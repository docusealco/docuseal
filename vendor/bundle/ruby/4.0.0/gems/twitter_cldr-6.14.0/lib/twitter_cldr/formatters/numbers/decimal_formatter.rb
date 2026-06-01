# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class DecimalFormatter < NumberFormatter

      def format(tokens, number, options = {})
        super
      rescue TypeError, ArgumentError
        number
      end

    end
  end
end