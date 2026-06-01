# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for `unless` expressions with `else` clauses.
      #
      # @example
      #   # bad
      #   unless foo_bar.nil?
      #     # do something...
      #   else
      #     # do a different thing...
      #   end
      #
      #   # good
      #   if foo_bar.present?
      #     # do something...
      #   else
      #     # do a different thing...
      #   end
      class UnlessElse < Base
        extend AutoCorrector

        MSG = 'Do not use `unless` with `else`. Rewrite these with the positive case first.'

        def on_if(node)
          return unless node.unless? && node.else?

          add_offense(node) do |corrector|
            next if part_of_ignored_node?(node)

            corrector.replace(node.loc.keyword, 'if')

            body_range = range_between_condition_and_else(node)
            else_range = range_between_else_and_end(node)

            corrector.swap(body_range, else_range)
          end

          ignore_node(node)
        end

        def range_between_condition_and_else(node)
          range = node.loc.begin ? node.loc.begin.end : node.condition.source_range

          range.end.join(node.loc.else.begin)
        end

        def range_between_else_and_end(node)
          node.loc.else.end.join(node.loc.end.begin)
        end
      end
    end
  end
end
