# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if empty lines exist around the arguments
      # of a method invocation.
      #
      # @example
      #   # bad
      #   do_something(
      #     foo
      #
      #   )
      #
      #   process(bar,
      #
      #           baz: qux,
      #           thud: fred)
      #
      #   some_method(
      #
      #     [1,2,3],
      #     x: y
      #   )
      #
      #   # good
      #   do_something(
      #     foo
      #   )
      #
      #   process(bar,
      #           baz: qux,
      #           thud: fred)
      #
      #   some_method(
      #     [1,2,3],
      #     x: y
      #   )
      #
      class EmptyLinesAroundArguments < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Empty line detected around arguments.'

        def on_send(node)
          return if node.single_line? || node.arguments.empty? ||
                    receiver_and_method_call_on_different_lines?(node)

          extra_lines(node) do |range|
            add_offense(range) do |corrector|
              corrector.remove(range)
            end
          end
        end
        alias on_csend on_send

        private

        def receiver_and_method_call_on_different_lines?(node)
          node.receiver && node.receiver.loc.last_line != node.loc.selector&.line
        end

        def extra_lines(node, &block)
          node.arguments.each do |arg|
            empty_range_for_starting_point(arg.source_range.begin, &block)
          end

          empty_range_for_starting_point(node.loc.end.begin, &block) if node.loc.end
        end

        def empty_range_for_starting_point(start)
          range = range_with_surrounding_space(start, whitespace: true, side: :left)
          return unless range.last_line - range.first_line > 1

          yield range.source_buffer.line_range(range.last_line - 1).adjust(end_pos: 1)
        end
      end
    end
  end
end
