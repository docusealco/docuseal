# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class PercentFormatter < NumberFormatter

      DEFAULT_PERCENT_SIGN = "%"

      def format(tokens, number, options = {})
        super(tokens, number, options).gsub('¤', data_reader.symbols[:percent_sign] || DEFAULT_PERCENT_SIGN)
      end

    end
  end
end
