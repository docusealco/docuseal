# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies places where `max_by { ... }`, `min_by { ... }`, or
      # `minmax_by { ... }` can be replaced by `max`, `min`, or `minmax`.
      #
      # @example
      #   # bad
      #   array.max_by { |x| x }
      #   array.min_by { |x| x }
      #   array.minmax_by { |x| x }
      #
      #   # good
      #   array.max
      #   array.min
      #   array.minmax
      class RedundantMinMaxBy < Base
        include RangeHelp
        extend AutoCorrector

        MSG_BLOCK = 'Use `%<replacement>s` instead of `%<original>s { |%<var>s| %<var>s }`.'
        MSG_NUMBLOCK = 'Use `%<replacement>s` instead of `%<original>s { _1 }`.'
        MSG_ITBLOCK = 'Use `%<replacement>s` instead of `%<original>s { it }`.'

        REPLACEMENTS = { max_by: 'max', min_by: 'min', minmax_by: 'minmax' }.freeze

        def on_block(node)
          redundant_minmax_by_block(node) do |send, var_name|
            register_offense(send, node, message_block(send, var_name))
          end
        end

        def on_numblock(node)
          redundant_minmax_by_numblock(node) do |send|
            register_offense(send, node, message_numblock(send))
          end
        end

        def on_itblock(node)
          redundant_minmax_by_itblock(node) do |send|
            register_offense(send, node, message_itblock(send))
          end
        end

        private

        # @!method redundant_minmax_by_block(node)
        def_node_matcher :redundant_minmax_by_block, <<~PATTERN
          (block $(call _ {:max_by :min_by :minmax_by}) (args (arg $_x)) (lvar _x))
        PATTERN

        # @!method redundant_minmax_by_numblock(node)
        def_node_matcher :redundant_minmax_by_numblock, <<~PATTERN
          (numblock $(call _ {:max_by :min_by :minmax_by}) 1 (lvar :_1))
        PATTERN

        # @!method redundant_minmax_by_itblock(node)
        def_node_matcher :redundant_minmax_by_itblock, <<~PATTERN
          (itblock $(call _ {:max_by :min_by :minmax_by}) _ (lvar :it))
        PATTERN

        def register_offense(send, node, message)
          range = offense_range(send, node)

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, REPLACEMENTS[send.method_name])
          end
        end

        def offense_range(send, node)
          range_between(send.loc.selector.begin_pos, node.loc.end.end_pos)
        end

        def message_block(send, var_name)
          method = send.method_name
          format(MSG_BLOCK, replacement: REPLACEMENTS[method], original: method, var: var_name)
        end

        def message_numblock(send)
          method = send.method_name
          format(MSG_NUMBLOCK, replacement: REPLACEMENTS[method], original: method)
        end

        def message_itblock(send)
          method = send.method_name
          format(MSG_ITBLOCK, replacement: REPLACEMENTS[method], original: method)
        end
      end
    end
  end
end
