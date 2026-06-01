# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Before Ruby 3.0, interpolated strings followed the frozen string literal
      # magic comment which sometimes made it necessary to explicitly unfreeze them.
      # Ruby 3.0 changed interpolated strings to always be unfrozen which makes
      # unfreezing them redundant.
      #
      # @example
      #   # bad
      #   +"#{foo} bar"
      #
      #   # bad
      #   "#{foo} bar".dup
      #
      #   # bad
      #   String.new("#{foo} bar")
      #
      #   # good
      #   "#{foo} bar"
      #
      class RedundantInterpolationUnfreeze < Base
        include FrozenStringLiteral
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = "Don't unfreeze interpolated strings as they are already unfrozen."

        minimum_target_ruby_version 3.0

        # @!method redundant_unfreeze?(node)
        def_node_matcher :redundant_unfreeze?, <<~PATTERN
          {
            (send dstr_type? {:+@ :dup})
            (send (const nil? :String) :new dstr_type?)
          }
        PATTERN

        def on_dstr(node)
          return if uninterpolated_string?(node) || uninterpolated_heredoc?(node)
          return unless redundant_unfreeze?(node.parent)

          add_offense(offense_range(node.parent)) do |corrector|
            corrector.replace(node.parent, node.source)
          end
        end

        private

        def offense_range(node)
          if node.method?(:new)
            node.source_range.begin.join(node.loc.selector)
          else
            node.loc.selector
          end
        end
      end
    end
  end
end
