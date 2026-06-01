# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for `each_with_object`, `inject`, and `reduce` calls that build
      # a hash from an enumerable, where `to_h` with a block could be used instead.
      #
      # This cop complements `Style/HashTransformKeys` and `Style/HashTransformValues`,
      # which handle hash-to-hash transformations with destructured key-value pairs.
      # This cop targets the case where a hash is built from individual elements
      # (non-destructured block parameter).
      #
      # @safety
      #   This cop is unsafe because it cannot guarantee that the receiver
      #   is an `Enumerable` by static analysis, so the correction may
      #   not be actually equivalent. Additionally, `each_with_object` returns
      #   the hash object while `to_h` returns a new hash, which could matter
      #   if the hash object identity is important.
      #
      # @example
      #   # bad
      #   array.each_with_object({}) { |elem, hash| hash[elem.id] = elem.name }
      #
      #   # bad
      #   array.inject({}) { |hash, elem| hash[elem.id] = elem.name; hash }
      #
      #   # bad
      #   array.reduce({}) { |hash, elem| hash[elem.id] = elem.name; hash }
      #
      #   # bad
      #   array.each_with_object({}) { |elem, hash| hash[elem] = elem.to_s }
      #
      #   # good
      #   array.to_h { |elem| [elem.id, elem.name] }
      #
      #   # good
      #   array.to_h { |elem| [elem, elem.to_s] }
      #
      class ReduceToHash < Base
        extend AutoCorrector
        extend TargetRubyVersion
        include RangeHelp

        minimum_target_ruby_version 2.6

        MSG = 'Use `to_h { ... }` instead of `%<method>s`.'
        RESTRICT_ON_SEND = %i[each_with_object inject reduce].freeze

        # each_with_object({}) { |elem, hash| hash[key] = value }
        # @!method each_with_object_to_hash?(node)
        def_node_matcher :each_with_object_to_hash?, <<~PATTERN
          {
            (block
              (call _ :each_with_object (hash))
              (args (arg _elem) (arg _hash))
              (send (lvar _hash) :[]= $_key $_value))
            (numblock
              (call _ :each_with_object (hash))
              2
              (send (lvar :_2) :[]= $_key $_value))
          }
        PATTERN

        # inject/reduce({}) { |hash, elem| hash[key] = value; hash }
        # @!method inject_to_hash?(node)
        def_node_matcher :inject_to_hash?, <<~PATTERN
          {
            (block
              (call _ {:inject :reduce} (hash))
              (args (arg _hash) (arg _elem))
              (begin
                (send (lvar _hash) :[]= $_key $_value)
                (lvar _hash)))
            (numblock
              (call _ {:inject :reduce} (hash))
              2
              (begin
                (send (lvar :_1) :[]= $_key $_value)
                (lvar :_1)))
          }
        PATTERN

        def on_send(node)
          block_node = node.block_node
          return unless block_node

          check_offense(node, block_node)
        end
        alias on_csend on_send

        private

        def check_offense(node, block_node)
          key, value = if node.method?(:each_with_object)
                         each_with_object_to_hash?(block_node)
                       else
                         inject_to_hash?(block_node)
                       end
          return unless key
          return if accumulator_used_in_expressions?(block_node, key, value)

          register_offense(node, block_node, key, value)
        end

        def accumulator_used_in_expressions?(block_node, key, value)
          acc_name = accumulator_name(block_node)
          references_variable?(key, acc_name) || references_variable?(value, acc_name)
        end

        def accumulator_name(block_node)
          index = block_node.method?(:each_with_object) ? 1 : 0
          block_node.argument_list[index].name
        end

        def references_variable?(node, name)
          node.each_node(:lvar).any? { |lvar| lvar.children.first == name }
        end

        def register_offense(send_node, block_node, key_expr, value_expr)
          message = format(MSG, method: send_node.method_name)

          add_offense(send_node.loc.selector, message: message) do |corrector|
            corrector.replace(
              replacement_range(send_node, block_node),
              replacement(block_node, key_expr, value_expr)
            )
          end
        end

        def replacement(block_node, key_expr, value_expr)
          key_source = adjusted_source(key_expr, block_node)
          value_source = adjusted_source(value_expr, block_node)
          body = "[#{key_source}, #{value_source}]"

          if block_node.numblock_type?
            block_node.braces? ? "to_h { #{body} }" : do_end_replacement(block_node, body)
          else
            named_block_replacement(block_node, body)
          end
        end

        def named_block_replacement(block_node, body)
          arg = element_arg_source(block_node)
          if block_node.braces?
            "to_h { |#{arg}| #{body} }"
          else
            do_end_replacement(block_node, body, arg)
          end
        end

        def do_end_replacement(block_node, body, arg = nil)
          args = arg ? " |#{arg}|" : ''
          "to_h do#{args}\n#{indent(block_node)}  #{body}\n#{indent(block_node)}end"
        end

        def replacement_range(send_node, block_node)
          range_between(send_node.loc.selector.begin_pos, block_node.source_range.end_pos)
        end

        def element_arg_source(block_node)
          if block_node.method?(:each_with_object)
            block_node.first_argument.source
          else
            block_node.arguments[1].source
          end
        end

        def adjusted_source(expr_node, block_node)
          source = expr_node.source
          return source unless block_node.numblock_type?
          return source if block_node.method?(:each_with_object)

          # For inject/reduce numblocks, _2 is the element (becomes _1)
          source.gsub('_2', '_1')
        end

        def indent(node)
          ' ' * node.source_range.column
        end
      end
    end
  end
end
