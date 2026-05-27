# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `map { |x| x.to_s }.join` and similar calls where the
      # `map` is redundant because `Array#join` implicitly calls `#to_s` on
      # each element.
      #
      # @safety
      #   This cop is unsafe because it cannot guarantee that the receiver
      #   is an `Array` by static analysis. If the receiver does not have
      #   an `Array#join`-compatible implementation (i.e. one that calls
      #   `#to_s` on elements), the correction may change behavior.
      #
      # @example
      #   # bad
      #   array.map(&:to_s).join(', ')
      #
      #   # bad
      #   array.map { |x| x.to_s }.join(', ')
      #
      #   # bad
      #   array.collect(&:to_s).join
      #
      #   # good
      #   array.join(', ')
      #
      #   # good
      #   array.join
      #
      class MapJoin < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Remove redundant `%<method>s(&:to_s)` before `join`.'
        RESTRICT_ON_SEND = %i[join].freeze

        # map(&:to_s).join(...)
        # @!method map_to_s_join?(node)
        def_node_matcher :map_to_s_join?, <<~PATTERN
          (call
            $(call _ ${:map :collect} (block_pass (sym :to_s)))
            :join ...)
        PATTERN

        # map { |x| x.to_s }.join(...)
        # @!method map_to_s_block_join?(node)
        def_node_matcher :map_to_s_block_join?, <<~PATTERN
          (call
            $(block
              (call _ ${:map :collect})
              (args (arg _x))
              (send (lvar _x) :to_s))
            :join ...)
        PATTERN

        # map { _1.to_s }.join(...)
        # @!method map_to_s_numblock_join?(node)
        def_node_matcher :map_to_s_numblock_join?, <<~PATTERN
          (call
            $(numblock
              (call _ ${:map :collect})
              1
              (send (lvar :_1) :to_s))
            :join ...)
        PATTERN

        # map { it.to_s }.join(...)
        # @!method map_to_s_itblock_join?(node)
        def_node_matcher :map_to_s_itblock_join?, <<~PATTERN
          (call
            $(itblock
              (call _ ${:map :collect})
              :it
              (send (lvar :it) :to_s))
            :join ...)
        PATTERN

        def on_send(node)
          map_to_s_join?(node) { |m, n| register_offense(node, m, n) } ||
            map_to_s_block_join?(node) { |m, n| register_offense(node, m, n) } ||
            map_to_s_numblock_join?(node) { |m, n| register_offense(node, m, n) } ||
            map_to_s_itblock_join?(node) { |m, n| register_offense(node, m, n) }
        end
        alias on_csend on_send

        private

        def register_offense(join_node, map_node, method_name)
          map_send = map_node.any_block_type? ? map_node.send_node : map_node
          message = format(MSG, method: method_name)

          add_offense(map_send.loc.selector, message: message) do |corrector|
            remove_map_call(corrector, join_node, map_node, map_send)
          end
        end

        def remove_map_call(corrector, join_node, map_node, map_send)
          receiver = map_send.receiver
          if receiver
            corrector.replace(removal_range(receiver, map_node, map_send), '')
          else
            corrector.replace(no_receiver_range(map_node, join_node), '')
          end
        end

        def removal_range(receiver, map_node, map_send)
          start_pos = if receiver.last_line < map_send.loc.dot.line
                        receiver.source_range.end_pos
                      else
                        map_send.loc.dot.begin_pos
                      end
          range_between(start_pos, map_node.source_range.end_pos)
        end

        def no_receiver_range(map_node, join_node)
          range_between(map_node.source_range.begin_pos, join_node.loc.dot.end_pos)
        end
      end
    end
  end
end
