# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for usage of method `fetch` or `Array.new` with default value argument
      # and block. In such cases, block will always be used as default value.
      #
      # This cop emulates Ruby warning "block supersedes default value argument" which
      # applies to `Array.new`, `Array#fetch`, `Hash#fetch`, `ENV.fetch` and
      # `Thread#fetch`.
      #
      # A `fetch` call without a receiver is considered a custom method and does not register
      # an offense.
      #
      # @safety
      #   This cop is unsafe because the receiver could have nonstandard implementation
      #   of `fetch`, or be a class other than the one listed above.
      #
      #   It is also unsafe because default value argument could have side effects:
      #
      #   [source,ruby]
      #   ----
      #   def x(a) = puts "side effect"
      #   Array.new(5, x(1)) { 2 }
      #   ----
      #
      #   so removing it would change behavior.
      #
      # @example
      #   # bad
      #   x.fetch(key, default_value) { block_value }
      #   Array.new(size, default_value) { block_value }
      #
      #   # good
      #   x.fetch(key) { block_value }
      #   Array.new(size) { block_value }
      #
      #   # also good - in case default value argument is desired instead
      #   x.fetch(key, default_value)
      #   Array.new(size, default_value)
      #
      #   # good - keyword arguments aren't registered as offenses
      #   x.fetch(key, keyword: :arg) { block_value }
      #
      # @example AllowedReceivers: ['Rails.cache']
      #   # good
      #   Rails.cache.fetch(name, options) { block }
      #
      class UselessDefaultValueArgument < Base
        include AllowedReceivers
        extend AutoCorrector

        MSG = 'Block supersedes default value argument.'

        RESTRICT_ON_SEND = %i[fetch new].freeze

        # @!method default_value_argument_and_block(node)
        def_node_matcher :default_value_argument_and_block, <<~PATTERN
          (any_block
            {
              (call !nil? :fetch $_key $_default_value)
              (send (const _ :Array) :new $_size $_default_value)
            }
            _args
            _block_body)
        PATTERN

        def on_send(node)
          return unless node.receiver

          unless (prev_arg_node, default_value_node = default_value_argument_and_block(node.parent))
            return
          end
          return if allowed_receiver?(node.receiver)
          return if hash_without_braces?(default_value_node)

          add_offense(default_value_node) do |corrector|
            corrector.remove(prev_arg_node.source_range.end.join(default_value_node.source_range))
          end
        end
        alias on_csend on_send

        private

        def hash_without_braces?(node)
          node.hash_type? && !node.braces?
        end
      end
    end
  end
end
