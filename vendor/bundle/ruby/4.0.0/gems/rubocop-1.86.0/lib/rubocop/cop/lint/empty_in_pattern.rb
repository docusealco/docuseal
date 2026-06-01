# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of `in` pattern branches without a body.
      #
      # @example
      #
      #   # bad
      #   case condition
      #   in [a]
      #     do_something
      #   in [a, b]
      #   end
      #
      #   # good
      #   case condition
      #   in [a]
      #     do_something
      #   in [a, b]
      #     nil
      #   end
      #
      # @example AllowComments: true (default)
      #
      #   # good
      #   case condition
      #   in [a]
      #     do_something
      #   in [a, b]
      #     # noop
      #   end
      #
      # @example AllowComments: false
      #
      #   # bad
      #   case condition
      #   in [a]
      #     do_something
      #   in [a, b]
      #     # noop
      #   end
      #
      class EmptyInPattern < Base
        extend TargetRubyVersion
        include CommentsHelp

        MSG = 'Avoid `in` branches without a body.'

        minimum_target_ruby_version 2.7

        def on_case_match(node)
          node.in_pattern_branches.each do |branch|
            next if branch.body
            next if allow_comments?(branch)

            add_offense(branch)
          end
        end

        private

        def allow_comments?(node)
          cop_config['AllowComments'] && contains_comments?(node) &&
            !comments_contain_disables?(node, name)
        end
      end
    end
  end
end
