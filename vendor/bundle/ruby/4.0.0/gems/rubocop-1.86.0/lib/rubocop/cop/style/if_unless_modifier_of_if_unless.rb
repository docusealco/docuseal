# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for if and unless statements used as modifiers of other if or
      # unless statements.
      #
      # @example
      #
      #   # bad
      #   tired? ? 'stop' : 'go faster' if running?
      #
      #   # bad
      #   if tired?
      #     "please stop"
      #   else
      #     "keep going"
      #   end if running?
      #
      #   # good
      #   if running?
      #     tired? ? 'stop' : 'go faster'
      #   end
      class IfUnlessModifierOfIfUnless < Base
        include StatementModifier
        extend AutoCorrector

        MSG = 'Avoid modifier `%<keyword>s` after another conditional.'

        # rubocop:disable Metrics/AbcSize
        def on_if(node)
          return unless node.modifier_form? && node.body.if_type?

          add_offense(node.loc.keyword, message: format(MSG, keyword: node.keyword)) do |corrector|
            corrector.wrap(node.if_branch, "#{node.keyword} #{node.condition.source}\n", "\nend")
            corrector.remove(node.if_branch.source_range.end.join(node.condition.source_range.end))
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
