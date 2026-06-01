# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Formatters
    class TimespanFormatter < Formatter

      def format(tokens, number, options = {})
        tokens.map(&:value).join.gsub(/\{[0-9]\}/, number.abs.to_s)
      end

    end
  end
end