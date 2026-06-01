# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use `include?(element)` instead of `intersect?([element])`.
      #
      # @safety
      #   The receiver might not be an array.
      #
      # @example
      #   # bad
      #   array.intersect?([element])
      #
      #   # good
      #   array.include?(element)
      class ArrayIntersectWithSingleElement < Base
        extend AutoCorrector

        MSG = 'Use `include?(element)` instead of `intersect?([element])`.'

        RESTRICT_ON_SEND = %i[intersect?].freeze

        # @!method single_element(node)
        def_node_matcher :single_element, <<~PATTERN
          (send _ _ $(array $_))
        PATTERN

        def on_send(node)
          array, element = single_element(node)
          return unless array

          add_offense(
            node.source_range.with(begin_pos: node.loc.selector.begin_pos)
          ) do |corrector|
            corrector.replace(node.loc.selector, 'include?')
            corrector.replace(
              array,
              array.percent_literal? ? element.value.inspect : element.source
            )
          end
        end
        alias on_csend on_send
      end
    end
  end
end
