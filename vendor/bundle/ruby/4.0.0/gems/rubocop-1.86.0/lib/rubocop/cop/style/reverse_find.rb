# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies places where `array.reverse.find` can be replaced by `array.rfind`.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is an `Array` or responds to the replacement method.
      #
      # @example
      #   # bad
      #   array.reverse.find { |item| item.even? }
      #   array.reverse.detect { |item| item.even? }
      #   array.reverse_each.find { |item| item.even? }
      #   array.reverse_each.detect { |item| item.even? }
      #
      #   # good
      #   array.rfind { |item| item.even? }
      #
      class ReverseFind < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use `rfind` instead.'
        RESTRICT_ON_SEND = %i[find detect].freeze

        minimum_target_ruby_version 4.0

        # @!method reverse_find?(node)
        def_node_matcher :reverse_find?, <<~PATTERN
          (call
            (call
              _ {:reverse :reverse_each}) {:find :detect} (block_pass sym)?)
        PATTERN

        def on_send(node)
          return unless reverse_find?(node)

          range = node.children.first.loc.selector.join(node.loc.selector)

          add_offense(range) do |corrector|
            corrector.replace(range, 'rfind')
          end
        end
        alias on_csend on_send
      end
    end
  end
end
