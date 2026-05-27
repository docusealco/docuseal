# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for manual counting patterns that can be replaced by `Enumerable#tally`.
      #
      # The cop detects the following patterns:
      #
      # - `each_with_object(Hash.new(0)) { |item, counts| counts[item] += 1 }`
      # - `group_by(&:itself).transform_values(&:count)`
      # - `group_by { |x| x }.transform_values(&:size)`
      # - `group_by { |x| x }.transform_values { |v| v.length }`
      #
      # @safety
      #   This cop is unsafe because it cannot guarantee that the receiver
      #   is an `Enumerable` by static analysis, so the correction may
      #   not be actually equivalent.
      #
      # @example
      #   # bad
      #   array.each_with_object(Hash.new(0)) { |item, counts| counts[item] += 1 }
      #
      #   # bad
      #   array.group_by(&:itself).transform_values(&:count)
      #
      #   # bad
      #   array.group_by { |item| item }.transform_values(&:size)
      #
      #   # bad
      #   array.group_by { |item| item }.transform_values { |v| v.length }
      #
      #   # good
      #   array.tally
      #
      class TallyMethod < Base
        extend AutoCorrector
        extend TargetRubyVersion
        include RangeHelp

        minimum_target_ruby_version 2.7

        MSG_EACH_WITH_OBJECT = 'Use `tally` instead of `each_with_object`.'
        MSG_GROUP_BY = 'Use `tally` instead of `group_by` and `transform_values`.'
        RESTRICT_ON_SEND = %i[each_with_object transform_values].freeze
        COUNTING_METHODS = %i[count size length].to_set.freeze

        # Pattern 1: collection.each_with_object(Hash.new(0)) { |elem, hash| hash[elem] += 1 }
        # @!method tally_each_with_object?(node)
        def_node_matcher :tally_each_with_object?, <<~PATTERN
          {
            (block
              (call _ :each_with_object
                (send (const {nil? cbase} :Hash) :new (int 0)))
              (args (arg _elem) (arg _hash))
              (op_asgn
                (send (lvar _hash) :[] (lvar _elem)) :+ (int 1)))
            (numblock
              (call _ :each_with_object
                (send (const {nil? cbase} :Hash) :new (int 0)))
              2
              (op_asgn
                (send (lvar :_2) :[] (lvar :_1)) :+ (int 1)))
          }
        PATTERN

        # Pattern 2: collection.group_by(&:itself).transform_values(&:count/size/length)
        # @!method tally_group_by_symbol?(node)
        def_node_matcher :tally_group_by_symbol?, <<~PATTERN
          (call
            (call _ :group_by (block_pass (sym :itself)))
            :transform_values
            (block_pass (sym %COUNTING_METHODS)))
        PATTERN

        # Pattern 3: collection.group_by { |x| x }.transform_values(&:count/size/length)
        # @!method tally_group_by_identity_block?(node)
        def_node_matcher :tally_group_by_identity_block?, <<~PATTERN
          (call
            {
              (block (call _ :group_by) (args (arg _x)) (lvar _x))
              (numblock (call _ :group_by) 1 (lvar :_1))
              (itblock (call _ :group_by) :it (lvar :it))
            }
            :transform_values
            (block_pass (sym %COUNTING_METHODS)))
        PATTERN

        # Pattern 4: collection.group_by(&:itself).transform_values { |v| v.count/size/length }
        #            collection.group_by { |x| x }.transform_values { |v| v.count/size/length }
        # @!method tally_group_by_transform_block?(node)
        def_node_matcher :tally_group_by_transform_block?, <<~PATTERN
          {
            (block
              (call
                {
                  (call _ :group_by (block_pass (sym :itself)))
                  (block (call _ :group_by) (args (arg _x)) (lvar _x))
                  (numblock (call _ :group_by) 1 (lvar :_1))
                  (itblock (call _ :group_by) :it (lvar :it))
                }
                :transform_values)
              (args (arg _v))
              (send (lvar _v) %COUNTING_METHODS))
            (numblock
              (call
                {
                  (call _ :group_by (block_pass (sym :itself)))
                  (block (call _ :group_by) (args (arg _x)) (lvar _x))
                  (numblock (call _ :group_by) 1 (lvar :_1))
                  (itblock (call _ :group_by) :it (lvar :it))
                }
                :transform_values)
              1
              (send (lvar :_1) %COUNTING_METHODS))
            (itblock
              (call
                {
                  (call _ :group_by (block_pass (sym :itself)))
                  (block (call _ :group_by) (args (arg _x)) (lvar _x))
                  (numblock (call _ :group_by) 1 (lvar :_1))
                  (itblock (call _ :group_by) :it (lvar :it))
                }
                :transform_values)
              :it
              (send (lvar :it) %COUNTING_METHODS))
          }
        PATTERN
        def on_send(node)
          if node.method?(:each_with_object)
            check_each_with_object(node)
          elsif node.method?(:transform_values)
            check_transform_values(node)
          end
        end
        alias on_csend on_send

        private

        def check_each_with_object(node)
          block_node = node.block_node
          return unless block_node
          return unless tally_each_with_object?(block_node)

          add_offense(node.loc.selector, message: MSG_EACH_WITH_OBJECT) do |corrector|
            corrector.replace(replacement_range(node, block_node), 'tally')
          end
        end

        def check_transform_values(node)
          if tally_group_by_symbol?(node) || tally_group_by_identity_block?(node)
            register_group_by_offense(node, node)
          elsif (block_node = node.block_node) && tally_group_by_transform_block?(block_node)
            register_group_by_offense(node, block_node)
          end
        end

        def register_group_by_offense(transform_node, end_node)
          group_by_node = group_by_send_node(transform_node)

          add_offense(group_by_node.loc.selector, message: MSG_GROUP_BY) do |corrector|
            corrector.replace(replacement_range(group_by_node, end_node), 'tally')
          end
        end

        def group_by_send_node(transform_node)
          receiver = transform_node.receiver
          if receiver.type?(:any_block)
            receiver.send_node
          else
            receiver
          end
        end

        def replacement_range(start_node, end_node)
          range_between(start_node.loc.selector.begin_pos, end_node.source_range.end_pos)
        end
      end
    end
  end
end
