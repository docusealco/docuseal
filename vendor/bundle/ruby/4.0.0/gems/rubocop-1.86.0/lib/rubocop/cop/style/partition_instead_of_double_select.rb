# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for consecutive calls to `select`/`filter`/`find_all` and `reject`
      # on the same receiver with the same block body, where `partition` could be
      # used instead. Also detects two `select` or two `reject` calls where one
      # block negates the other with `!`. Using `partition` reduces two collection
      # traversals to one.
      #
      # @safety
      #   This cop is unsafe because:
      #
      #   * `Hash#select` and `Hash#reject` return hashes, but `Hash#partition`
      #     returns nested arrays.
      #   * When the receiver has side effects, calling it once (with `partition`)
      #     versus twice (with `select` + `reject`) may produce different results.
      #   * Custom classes may override `select`/`reject` without providing a
      #     compatible `partition` method.
      #
      # @example
      #   # bad
      #   positives = array.select { |x| x > 0 }
      #   negatives = array.reject { |x| x > 0 }
      #
      #   # bad
      #   positives = array.filter { |x| x > 0 }
      #   negatives = array.reject { |x| x > 0 }
      #
      #   # bad
      #   negatives = array.reject { |x| x > 0 }
      #   positives = array.select { |x| x > 0 }
      #
      #   # bad
      #   positives = array.select(&:positive?)
      #   negatives = array.reject(&:positive?)
      #
      #   # bad
      #   positives = array.select(&:positive?)
      #   negatives = array.reject { |x| x.positive? }
      #
      #   # bad
      #   positives = array.select { |x| x.positive? }
      #   non_positives = array.select { |x| !x.positive? }
      #
      #   # good
      #   positives, negatives = array.partition { |x| x > 0 }
      #
      #   # good
      #   positives, non_positives = array.partition { |x| x.positive? }
      #
      #   # good
      #   positives, negatives = array.partition(&:positive?)
      #
      class PartitionInsteadOfDoubleSelect < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `partition` instead of consecutive `%<first>s` and `%<second>s` calls.'

        SELECT_METHODS = %i[select filter find_all].freeze
        CANDIDATE_METHODS = (SELECT_METHODS + %i[reject]).to_set.freeze
        RESTRICT_ON_SEND = (SELECT_METHODS + %i[reject]).freeze

        # @!method symbol_proc_method?(node)
        def_node_matcher :symbol_proc_method?, <<~PATTERN
          (block _ (args (arg _name)) (send (lvar _name) $_method_name))
        PATTERN

        def on_block(node)
          return unless CANDIDATE_METHODS.include?(node.method_name)

          find_and_register_offense(node)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        def on_send(node)
          return unless node.last_argument&.block_pass_type?

          find_and_register_offense(node)
        end
        alias on_csend on_send

        private

        def find_and_register_offense(node)
          container = node_container(node)
          return unless container

          sibling_container = container.left_sibling
          sibling = find_matching_candidate(node, sibling_container)
          return unless sibling

          register_offense(node, sibling, container, sibling_container)
        end

        def node_container(node)
          parent = node.parent
          if parent&.begin_type?
            node
          elsif parent&.assignment? && parent.parent&.begin_type?
            parent
          end
        end

        def find_matching_candidate(node, sibling_container)
          return unless sibling_container

          sibling = extract_candidate(sibling_container)
          return unless sibling
          return unless node.receiver == sibling.receiver
          return unless matching_pair?(node, sibling)

          sibling
        end

        def matching_pair?(node, sibling)
          (complementary_pair?(node, sibling) && equivalent_predicate?(node, sibling)) ||
            (node.method?(sibling.method_name) && negated_predicate?(node, sibling))
        end

        def extract_candidate(container)
          extract_block(container) || extract_block_pass_send(container)
        end

        def extract_block(container)
          if container.any_block_type?
            container
          elsif container.assignment?
            rhs = container.children.last
            rhs if rhs&.any_block_type?
          end
        end

        def extract_block_pass_send(container)
          node = container.assignment? ? container.children.last : container
          return unless node&.type?(:call)
          return unless node.last_argument&.block_pass_type?

          node
        end

        def complementary_pair?(node1, node2)
          m1 = node1.method_name
          m2 = node2.method_name
          (SELECT_METHODS.include?(m1) && m2 == :reject) ||
            (m1 == :reject && SELECT_METHODS.include?(m2))
        end

        def equivalent_predicate?(node1, node2)
          if node1.any_block_type? && node2.any_block_type?
            same_block_contents?(node1, node2)
          elsif node1.any_block_type?
            block_matches_block_pass?(node1, node2)
          elsif node2.any_block_type?
            block_matches_block_pass?(node2, node1)
          else
            node1.last_argument == node2.last_argument
          end
        end

        def same_block_contents?(block1, block2)
          return false unless block1.type == block2.type

          if block1.block_type?
            block1.arguments == block2.arguments &&
              block1.body == block2.body
          else
            block1.body == block2.body
          end
        end

        def block_matches_block_pass?(block_node, send_node)
          method_name = symbol_proc_method?(block_node)
          return false unless method_name

          sym_node = send_node.last_argument.children.first
          sym_node.sym_type? && sym_node.children.first == method_name
        end

        def negated_predicate?(node1, node2)
          return false unless node1.any_block_type? && node2.any_block_type?
          return false unless node1.type == node2.type
          return false if node1.block_type? && node1.arguments != node2.arguments

          negated_body?(node1.body, node2.body) || negated_body?(node2.body, node1.body)
        end

        def negated_body?(body1, body2)
          body1&.send_type? && body1.method?(:!) && body1.receiver == body2
        end

        def register_offense(node, sibling, container, sibling_container)
          message = format(MSG, first: sibling.method_name, second: node.method_name)

          add_offense(container, message: message) do |corrector|
            next unless both_lvasgn?(container, sibling_container)

            autocorrect(corrector, node, sibling, container, sibling_container)
          end
        end

        def both_lvasgn?(container, sibling_container)
          container.lvasgn_type? && sibling_container.lvasgn_type?
        end

        def autocorrect(corrector, node, sibling, container, sibling_container)
          if complementary_pair?(node, sibling)
            select_var, reject_var =
              complementary_variable_order(sibling, container, sibling_container)
            partition_node = select_node_for(sibling, container)
          else
            select_var, reject_var, partition_node =
              negation_partition_args(node, sibling, container, sibling_container)
          end

          partition_call = build_partition_call(partition_node)
          replacement = "#{select_var}, #{reject_var} = #{partition_call}"

          corrector.replace(sibling_container, replacement)
          range = range_by_whole_lines(container.source_range, include_final_newline: true)
          corrector.remove(range)
        end

        def complementary_variable_order(sibling, container, sibling_container)
          if SELECT_METHODS.include?(sibling.method_name)
            [sibling_container.children.first, container.children.first]
          else
            [container.children.first, sibling_container.children.first]
          end
        end

        def negation_partition_args(node, sibling, container, sibling_container)
          node_is_negated = negated_body?(node.body, sibling.body)
          is_select = SELECT_METHODS.include?(node.method_name)
          # For select: non-negated is truthy (first). For reject: negated is truthy (first).
          node_is_truthy = is_select != node_is_negated
          partition_node = node_is_negated ? sibling : node

          if node_is_truthy
            [container.children.first, sibling_container.children.first, partition_node]
          else
            [sibling_container.children.first, container.children.first, partition_node]
          end
        end

        def select_node_for(sibling, container)
          if SELECT_METHODS.include?(sibling.method_name)
            sibling
          else
            container.children.last
          end
        end

        def build_partition_call(node)
          source = node.source
          send_node = node.any_block_type? ? node.send_node : node
          selector = send_node.loc.selector
          offset = node.source_range.begin_pos
          method_start = selector.begin_pos - offset
          method_end = selector.end_pos - offset

          "#{source[0...method_start]}partition#{source[method_end..]}"
        end
      end
    end
  end
end
