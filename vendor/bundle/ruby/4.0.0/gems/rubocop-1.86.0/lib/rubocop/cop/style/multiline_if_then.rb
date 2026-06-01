# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the `then` keyword in multi-line `if` statements.
      # In multi-line `if` statements, `then` is redundant because the newline
      # already separates the condition from the body.
      #
      # @example
      #   # bad
      #   # This is considered bad practice.
      #   if cond then
      #   end
      #
      #   # good
      #   # If statements can contain `then` on the same line.
      #   if cond then a
      #   elsif cond then b
      #   end
      class MultilineIfThen < Base
        include OnNormalIfUnless
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use `then` for multi-line `%<keyword>s`.'

        def on_normal_if_unless(node)
          return unless non_modifier_then?(node)

          add_offense(node.loc.begin, message: format(MSG, keyword: node.keyword)) do |corrector|
            corrector.remove(range_with_surrounding_space(node.loc.begin, side: :left))
          end
        end

        private

        def non_modifier_then?(node)
          node.then? && node.loc.begin.line != node.if_branch&.loc&.line
        end
      end
    end
  end
end
