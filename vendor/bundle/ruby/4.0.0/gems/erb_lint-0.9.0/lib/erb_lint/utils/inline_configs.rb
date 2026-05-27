# frozen_string_literal: true

module ERBLint
  module Utils
    class InlineConfigs
      def self.rule_disable_comment_for_lines?(rule, lines)
        lines.match?(/# erb_?lint:disable (?<rules>.*#{rule}).*/)
      end

      def self.disabled_rules(line)
        line.match(/# erb_?lint:disable (?<rules>.*) %>/)&.named_captures&.fetch("rules")
      end
    end
  end
end
