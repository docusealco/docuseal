# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of either `Hash#[]` or `Hash#fetch` for hash lookup.
      #
      # This cop can be configured to prefer either bracket-style (`[]`)
      # or fetch-style lookup. It is disabled by default.
      #
      # When enforcing `fetch` style, only single-argument bracket access is flagged.
      # When enforcing `brackets` style, only `fetch` calls with a single key
      # argument are flagged (not those with default values or blocks).
      #
      # @safety
      #   This cop is unsafe because `Hash#[]` and `Hash#fetch` have different
      #   semantics. `Hash#[]` returns `nil` for missing keys, while `Hash#fetch`
      #   raises a `KeyError`. Replacing one with the other can change program
      #   behavior in cases where the key is missing.
      #
      #   Additionally, it cannot be guaranteed that the receiver is a `Hash`
      #   or responds to the replacement method.
      #
      # @example EnforcedStyle: brackets (default)
      #   # bad
      #   hash.fetch(key)
      #
      #   # good
      #   hash[key]
      #
      #   # good - fetch with default value is allowed
      #   hash.fetch(key, default)
      #
      #   # good - fetch with block is allowed
      #   hash.fetch(key) { default }
      #
      # @example EnforcedStyle: fetch
      #   # bad
      #   hash[key]
      #
      #   # good
      #   hash.fetch(key)
      #
      # @example AllowedReceivers: ['Rails.cache']
      #   # good
      #   Rails.cache.fetch(name, options) { block }
      #
      class HashLookupMethod < Base
        include ConfigurableEnforcedStyle
        include AllowedReceivers
        extend AutoCorrector

        BRACKET_MSG = 'Use `Hash#[]` instead of `Hash#fetch`.'
        FETCH_MSG = 'Use `Hash#fetch` instead of `Hash#[]`.'

        RESTRICT_ON_SEND = %i[[] fetch].freeze

        def on_send(node)
          return if (receiver = node.receiver) && allowed_receiver?(receiver)

          if offense_for_brackets?(node)
            add_offense(node.loc.selector, message: BRACKET_MSG) do |corrector|
              correct_fetch_to_brackets(corrector, node)
            end
          elsif offense_for_fetch?(node)
            add_offense(node, message: FETCH_MSG) do |corrector|
              correct_brackets_to_fetch(corrector, node)
            end
          end
        end
        alias on_csend on_send

        private

        def offense_for_brackets?(node)
          style == :brackets && node.receiver && node.method?(:fetch) && node.arguments.one? &&
            !node.block_literal?
        end

        def offense_for_fetch?(node)
          style == :fetch && node.method?(:[]) && node.arguments.one?
        end

        def correct_fetch_to_brackets(corrector, node)
          receiver = node.receiver.source
          key = node.first_argument.source
          replacement = "#{receiver}[#{key}]"
          replacement = "(#{replacement})" if node.csend_type?
          corrector.replace(node, replacement)
        end

        def correct_brackets_to_fetch(corrector, node)
          receiver = node.receiver.source
          key = node.first_argument.source
          operator = node.csend_type? ? '&.' : '.'
          corrector.replace(node, "#{receiver}#{operator}fetch(#{key})")
        end
      end
    end
  end
end
