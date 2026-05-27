# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'singleton'

module TwitterCldr
  module Transforms

    class CommentRule < Rule
      include Singleton

      class << self
        def parse(rule_text, symbol_table, index)
          instance
        end

        def accepts?(rule_text)
          rule_text.strip.start_with?('#')
        end
      end

      def is_comment?
        true
      end
    end

  end
end
