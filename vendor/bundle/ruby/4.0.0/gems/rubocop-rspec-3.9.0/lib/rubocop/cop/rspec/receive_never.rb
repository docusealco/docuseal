# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Prefer `not_to receive(...)` over `receive(...).never`.
      #
      # This cop only flags usage with `expect`. It ignores `allow` because
      # `allow(...).to receive(...).never` is a valid way to ensure a method
      # is not called, while `allow(...).not_to receive(...)` would have
      # different semantics.
      #
      # @example
      #   # bad
      #   expect(foo).to receive(:bar).never
      #
      #   # good
      #   expect(foo).not_to receive(:bar)
      #
      #   # not flagged by this cop
      #   allow(foo).to receive(:bar).never
      #
      class ReceiveNever < Base
        extend AutoCorrector
        MSG = 'Use `not_to receive` instead of `never`.'
        RESTRICT_ON_SEND = %i[never].freeze

        # @!method method_on_stub?(node)
        def_node_search :method_on_stub?, '(send nil? :receive ...)'

        # @!method expect_to_receive?(node)
        def_node_matcher :expect_to_receive?, <<~PATTERN
          (send
            {
              (send #rspec? {:expect :expect_any_instance_of} ...)
              (block (send #rspec? :expect) ...)
              (send nil? :is_expected)
            }
            :to ...)
        PATTERN

        def on_send(node)
          return unless node.method?(:never) && method_on_stub?(node)
          return unless used_with_expect?(node)

          add_offense(node.loc.selector) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def used_with_expect?(node)
          node.each_ancestor(:send).any? do |ancestor|
            expect_to_receive?(ancestor)
          end
        end

        def autocorrect(corrector, node)
          corrector.replace(node.parent.loc.selector, 'not_to')
          range = node.loc.dot.with(end_pos: node.loc.selector.end_pos)
          corrector.remove(range)
        end
      end
    end
  end
end
