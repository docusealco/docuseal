# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for redundant calls of `Array#flatten`.
      #
      # `Array#join` joins nested arrays recursively, so flattening an array
      # beforehand is redundant.
      #
      # @safety
      #   Cop is unsafe because the receiver of `flatten` method might not
      #   be an `Array`, so it's possible it won't respond to `join` method,
      #   or the end result would be different.
      #   Also, if the global variable `$,` is set to a value other than the default `nil`,
      #   false positives may occur.
      #
      # @example
      #   # bad
      #   x.flatten.join
      #   x.flatten(1).join
      #
      #   # good
      #   x.join
      #
      class RedundantArrayFlatten < Base
        extend AutoCorrector

        MSG = 'Remove the redundant `flatten`.'

        RESTRICT_ON_SEND = %i[flatten].freeze

        # @!method flatten_join?(node)
        def_node_matcher :flatten_join?, <<~PATTERN
          (call (call !nil? :flatten _?) :join (nil)?)
        PATTERN

        def on_send(node)
          return unless flatten_join?(node.parent)

          range = node.loc.dot.begin.join(node.source_range.end)
          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end
        alias on_csend on_send
      end
    end
  end
end
