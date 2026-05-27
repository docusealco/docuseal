# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Prefer `Enumerable` predicate methods over expressions with `count`.
      #
      # The cop checks calls to `count` without arguments, or with a
      # block. It doesn't register offenses for `count` with a positional
      # argument because its behavior differs from predicate methods (`count`
      # matches the argument using `==`, while `any?`, `none?` and `one?` use
      # `===`).
      #
      # NOTE: This cop doesn't check `length` and `size` methods because they
      # would yield false positives. For example, `String` implements `length`
      # and `size`, but it doesn't include `Enumerable`.
      #
      # @safety
      #   The cop is unsafe because receiver might not include `Enumerable`, or
      #   it has nonstandard implementation of `count` or any replacement
      #   methods.
      #
      #   It's also unsafe because for collections with falsey values, expressions
      #   with `count` without a block return a different result than methods `any?`,
      #   `none?` and `one?`:
      #
      #   [source,ruby]
      #   ----
      #   [nil, false].count.positive?
      #   [nil].count == 1
      #   # => true
      #
      #   [nil, false].any?
      #   [nil].one?
      #   # => false
      #
      #   [nil].count == 0
      #   # => false
      #
      #   [nil].none?
      #   # => true
      #   ----
      #
      #   Autocorrection is unsafe when replacement methods don't iterate over
      #   every element in collection and the given block runs side effects:
      #
      #   [source,ruby]
      #   ----
      #   x.count(&:method_with_side_effects).positive?
      #   # calls `method_with_side_effects` on every element
      #
      #   x.any?(&:method_with_side_effects)
      #   # calls `method_with_side_effects` until first element returns a truthy value
      #   ----
      #
      # @example
      #
      #   # bad
      #   x.count.positive?
      #   x.count > 0
      #   x.count != 0
      #
      #   x.count(&:foo?).positive?
      #   x.count { |item| item.foo? }.positive?
      #
      #   # good
      #   x.any?
      #
      #   x.any?(&:foo?)
      #   x.any? { |item| item.foo? }
      #
      #   # bad
      #   x.count.zero?
      #   x.count == 0
      #
      #   # good
      #   x.none?
      #
      #   # bad
      #   x.count == 1
      #   x.one?
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #
      #   # good
      #   x.count > 1
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #
      #   # bad
      #   x.count > 1
      #
      #   # good
      #   x.many?
      #
      class CollectionQuerying < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead.'

        RESTRICT_ON_SEND = %i[positive? > != zero? ==].freeze

        REPLACEMENTS = {
          [:positive?, nil] => :any?,
          [:>, 0] => :any?,
          [:!=, 0] => :any?,
          [:zero?, nil] => :none?,
          [:==, 0] => :none?,
          [:==, 1] => :one?,
          [:>, 1] => :many?
        }.freeze

        # @!method count_predicate(node)
        def_node_matcher :count_predicate, <<~PATTERN
          (send
            {
              (any_block $(call !nil? :count) _ _)
              $(call !nil? :count (block-pass _)?)
            }
            {
              :positive? |
              :> (int 0) |
              :!= (int 0) |
              :zero? |
              :== (int 0) |
              :== (int 1) |
              :> (int 1)
            })
        PATTERN

        def on_send(node)
          return unless (count_node = count_predicate(node))

          replacement_method = replacement_method(node)

          return unless replacement_supported?(replacement_method)

          offense_range = count_node.loc.selector.join(node.source_range.end)
          add_offense(offense_range,
                      message: format(MSG, prefer: replacement_method)) do |corrector|
            corrector.replace(count_node.loc.selector, replacement_method)
            corrector.remove(removal_range(node))
          end
        end

        private

        def replacement_method(node)
          REPLACEMENTS.fetch([node.method_name, node.first_argument&.value])
        end

        def replacement_supported?(method_name)
          return true if active_support_extensions_enabled?

          method_name != :many?
        end

        def removal_range(node)
          range = (node.loc.dot || node.loc.selector).join(node.source_range.end)

          range_with_surrounding_space(range, side: :left)
        end
      end
    end
  end
end
