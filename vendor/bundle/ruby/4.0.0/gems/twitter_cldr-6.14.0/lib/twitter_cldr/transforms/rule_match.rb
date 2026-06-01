# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    class RuleMatch
      attr_reader :rule, :side_match

      def initialize(rule, side_match)
        @rule = rule
        @side_match = side_match
      end

      def start
        side_match.start
      end

      def stop
        side_match.stop
      end

      def replacement
        rule.replacement_for(side_match)
      end

      def cursor_offset
        rule.cursor_offset
      end

      def <(other_match)
        rule.index < other_match.rule.index
      end
    end
  end
end
