# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for space between the name of a receiver and a left
      # brackets.
      #
      # @example
      #
      #   # bad
      #   collection [index_or_key]
      #
      #   # good
      #   collection[index_or_key]
      #
      class SpaceBeforeBrackets < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Remove the space before the opening brackets.'
        RESTRICT_ON_SEND = %i[[] []=].freeze

        def on_send(node)
          return if node.loc.dot

          receiver_end_pos = node.receiver.source_range.end_pos
          selector_begin_pos = node.loc.selector.begin_pos
          return if receiver_end_pos >= selector_begin_pos

          range = range_between(receiver_end_pos, selector_begin_pos)

          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end
      end
    end
  end
end
