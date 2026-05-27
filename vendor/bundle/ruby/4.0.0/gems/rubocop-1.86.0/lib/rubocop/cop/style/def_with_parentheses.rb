# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for parentheses in the definition of a method,
      # that does not take any arguments. Both instance and
      # class/singleton methods are checked.
      #
      # @example
      #
      #   # bad
      #   def foo()
      #     do_something
      #   end
      #
      #   # good
      #   def foo
      #     do_something
      #   end
      #
      #   # bad
      #   def foo() = do_something
      #
      #   # good
      #   def foo = do_something
      #
      #   # good - without parentheses it's a syntax error
      #   def foo() do_something end
      #   def foo()=do_something
      #
      #   # bad
      #   def Baz.foo()
      #     do_something
      #   end
      #
      #   # good
      #   def Baz.foo
      #     do_something
      #   end
      class DefWithParentheses < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Omit the parentheses in defs when the method doesn't accept any arguments."

        def on_def(node)
          return unless !node.arguments? && (arguments_range = node.arguments.source_range)
          return if parentheses_required?(node, arguments_range)

          add_offense(arguments_range) do |corrector|
            corrector.remove(arguments_range)
          end
        end
        alias on_defs on_def

        private

        def parentheses_required?(node, arguments_range)
          return true if node.single_line? && !node.endless?

          end_pos = arguments_range.end.end_pos
          token_after_argument = range_between(end_pos, end_pos + 1).source

          token_after_argument == '='
        end
      end
    end
  end
end
