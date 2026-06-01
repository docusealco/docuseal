# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of the method name part in method calls
      # that span more than one line.
      #
      # @example EnforcedStyle: aligned (default)
      #   # bad
      #   while myvariable
      #   .b
      #     # do something
      #   end
      #
      #   # good
      #   while myvariable
      #         .b
      #     # do something
      #   end
      #
      #   # good
      #   Thing.a
      #        .b
      #        .c
      #
      # @example EnforcedStyle: indented
      #   # good
      #   while myvariable
      #     .b
      #
      #     # do something
      #   end
      #
      # @example EnforcedStyle: indented_relative_to_receiver
      #   # good
      #   while myvariable
      #           .a
      #           .b
      #
      #     # do something
      #   end
      #
      #   # good
      #   myvariable = Thing
      #                  .a
      #                  .b
      #                  .c
      #
      class MultilineMethodCallIndentation < Base # rubocop:disable Metrics/ClassLength
        include ConfigurableEnforcedStyle
        include Alignment
        include MultilineExpressionIndentation
        include RangeHelp
        extend AutoCorrector

        def validate_config
          return unless style == :aligned && cop_config['IndentationWidth']

          raise ValidationError,
                'The `Layout/MultilineMethodCallIndentation` ' \
                'cop only accepts an `IndentationWidth` ' \
                'configuration parameter when ' \
                '`EnforcedStyle` is `indented`.'
        end

        private

        def find_base_receiver(node)
          base_receiver = node
          base_receiver = base_receiver.receiver while base_receiver.receiver
          base_receiver
        end

        def find_pair_ancestor(node)
          node.each_ancestor.find(&:pair_type?)
        end

        def unwrap_block_node(node)
          node&.any_block_type? ? node.send_node : node
        end

        def autocorrect(corrector, node)
          if @send_node.block_node
            correct_selector_only(corrector, node)
            correct_block(corrector, @send_node.block_node)
          else
            AlignmentCorrector.correct(corrector, processed_source, node, @column_delta)
          end
        end

        def correct_selector_only(corrector, node)
          selector_line = processed_source.buffer.line_range(node.first_line)
          selector_range = range_between(selector_line.begin_pos, selector_line.end_pos)
          AlignmentCorrector.correct(corrector, processed_source, selector_range, @column_delta)
        end

        def correct_block(corrector, block_node)
          AlignmentCorrector.correct(corrector, processed_source, block_node.body, @column_delta)
          end_range = range_by_whole_lines(block_node.loc.end, include_final_newline: false)
          AlignmentCorrector.correct(corrector, processed_source, end_range, @column_delta)
        end

        def relevant_node?(send_node)
          send_node.loc.dot # Only check method calls with dot operator
        end

        def right_hand_side(send_node)
          dot = send_node.loc.dot
          selector = send_node.loc.selector
          if (send_node.dot? || send_node.safe_navigation?) && selector && same_line?(dot, selector)
            dot.join(selector)
          elsif selector
            selector
          elsif send_node.implicit_call?
            dot.join(send_node.loc.begin)
          end
        end

        def offending_range(node, lhs, rhs, given_style)
          return false unless begins_its_line?(rhs)

          @send_node = node # Store for use in autocorrect
          pair_ancestor = find_pair_ancestor(node)
          if hash_pair_aligned?(pair_ancestor, given_style)
            return check_hash_pair_indentation(node, lhs, rhs)
          end
          if hash_pair_indented?(node, pair_ancestor, given_style)
            return check_hash_pair_indented_style(rhs, pair_ancestor)
          end
          return false if skip_for_context?(node, pair_ancestor)

          check_regular_indentation(node, lhs, rhs, given_style)
        end

        def skip_for_context?(node, pair_ancestor)
          pair_ancestor ? inside_multiline_chain_arg?(node) : not_for_this_cop?(node)
        end

        def hash_pair_aligned?(pair_ancestor, given_style)
          pair_ancestor && given_style == :aligned
        end

        def hash_pair_indented?(node, pair_ancestor, given_style)
          pair_ancestor && given_style == :indented && find_base_receiver(node).hash_type?
        end

        def check_hash_pair_indented_style(rhs, pair_ancestor)
          pair_key = pair_ancestor.key
          double_indentation = configured_indentation_width * 2
          correct_column = pair_key.source_range.column + double_indentation
          @hash_pair_base_column = pair_key.source_range.column + configured_indentation_width

          calculate_column_delta_offense(rhs, correct_column)
        end

        def check_hash_pair_indentation(node, lhs, rhs)
          @base = find_hash_pair_alignment_base(node)
          return false if !@base && inside_multiline_chain_arg?(node)

          @base ||= lhs.source_range
          return if aligned_with_first_line_dot?(node, rhs)

          calculate_column_delta_offense(rhs, @base.column)
        end

        def find_hash_pair_alignment_base(node)
          base_receiver = find_base_receiver(node.receiver)
          return unless base_receiver.hash_type?

          first_call = first_call_has_a_dot(node)
          first_call.loc.dot.join(first_call.loc.selector)
        end

        def inside_multiline_chain_arg?(node)
          enclosing_call = find_enclosing_chain_call(node)
          return false unless enclosing_call

          !same_line?(enclosing_call.loc.selector, enclosing_call.receiver.source_range)
        end

        def find_enclosing_chain_call(node)
          hash_ancestor = find_pair_ancestor(node).parent
          enclosing_call = hash_ancestor.parent
          return unless hash_arg_in_chain?(enclosing_call, hash_ancestor)

          enclosing_call
        end

        def hash_arg_in_chain?(call, hash_node)
          call&.call_type? && call.receiver != hash_node && call.loc?(:dot)
        end

        def aligned_with_first_line_dot?(node, rhs)
          return false unless rhs.source.start_with?('.', '&.')

          first_call = first_call_has_a_dot(node)
          return false if first_call == node.receiver

          dot = first_call.loc.dot
          dot.line == node.first_line && dot.column == rhs.column
        end

        def check_regular_indentation(node, lhs, rhs, given_style)
          @base = alignment_base(node, rhs, given_style)
          correct_column = if @base
                             parent = node.parent
                             parent = parent.parent if parent&.any_block_type?
                             @base.column + extra_indentation(given_style, parent)
                           else
                             indentation(lhs) + correct_indentation(node)
                           end

          calculate_column_delta_offense(rhs, correct_column)
        end

        def calculate_column_delta_offense(rhs, correct_column)
          @column_delta = correct_column - rhs.column
          rhs if @column_delta.nonzero?
        end

        def extra_indentation(given_style, parent)
          return 0 unless given_style == :indented_relative_to_receiver

          if parent&.type?(:splat, :kwsplat)
            configured_indentation_width - parent.loc.operator.length
          else
            configured_indentation_width
          end
        end

        def message(node, lhs, rhs)
          if should_indent_relative_to_receiver?
            relative_to_receiver_message(rhs)
          elsif should_align_with_base?
            align_with_base_message(rhs)
          else
            no_base_message(lhs, rhs, node)
          end
        end

        def should_indent_relative_to_receiver?
          @base && style == :indented_relative_to_receiver
        end

        def should_align_with_base?
          @base && style == :aligned
        end

        def relative_to_receiver_message(rhs)
          "Indent `#{rhs.source}` #{configured_indentation_width} spaces " \
            "more than `#{base_source}` on line #{@base.line}."
        end

        def align_with_base_message(rhs)
          "Align `#{rhs.source}` with `#{base_source}` on line #{@base.line}."
        end

        def base_source
          @base.source[/[^\n]*/]
        end

        def no_base_message(lhs, rhs, node)
          if @hash_pair_base_column
            used_indentation = rhs.column - @hash_pair_base_column
            expected_indentation = configured_indentation_width
          else
            used_indentation = rhs.column - indentation(lhs)
            expected_indentation = correct_indentation(node)
          end
          what = operation_description(node, rhs)

          "Use #{expected_indentation} (not #{used_indentation}) " \
            "spaces for indenting #{what} spanning multiple lines."
        end

        def alignment_base(node, rhs, given_style)
          case given_style
          when :aligned
            semantic_alignment_base(node, rhs) || syntactic_alignment_base(node, rhs)
          when :indented_relative_to_receiver
            receiver_alignment_base(node)
          end
        end

        def syntactic_alignment_base(lhs, rhs)
          # a if b
          #      .c
          kw_node_with_special_indentation(lhs) do |base|
            return indented_keyword_expression(base).source_range
          end

          # a = b
          #     .c
          part_of_assignment_rhs(lhs, rhs) { |base| return assignment_rhs(base).source_range }

          # a + b
          #     .c
          operation_rhs(lhs) { |base| return base.source_range }
        end

        # a.b
        #  .c
        def semantic_alignment_base(node, rhs)
          return unless rhs.source.start_with?('.', '&.')

          node = semantic_alignment_node(node)
          return unless node&.loc?(:selector) && node.loc.dot

          node.loc.dot.join(node.loc.selector)
        end

        # a
        #   .b
        #   .c
        def receiver_alignment_base(node)
          hash_method_base = find_hash_method_base_in_receiver_chain(node)
          return hash_method_base if hash_method_base

          first_call = first_call_has_a_dot(node)
          first_call.receiver.source_range
        end

        def find_hash_method_base_in_receiver_chain(node)
          receiver_chain = unwrap_block_node(node.receiver)
          while receiver_chain&.call_type?
            base_receiver = unwrap_block_node(receiver_chain.receiver)
            if alignment_base_for_chained_receiver?(receiver_chain, base_receiver)
              return receiver_chain.loc.dot.join(receiver_chain.loc.selector)
            end

            receiver_chain = base_receiver
          end
        end

        def alignment_base_for_chained_receiver?(receiver_chain, base_receiver)
          base_receiver&.hash_type? ||
            method_on_receiver_last_line?(receiver_chain, base_receiver, :begin)
        end

        def semantic_alignment_node(node)
          return if argument_in_method_call(node, :with_parentheses)

          get_dot_right_above(node) ||
            find_multiline_block_chain_node(node) ||
            first_call_alignment_node(node)
        end

        def first_call_alignment_node(node)
          node = first_call_has_a_dot(node)
          base_receiver = find_base_receiver(node)

          return node if method_on_receiver_last_line?(node, base_receiver, :array)
          return if node.loc.dot.line != node.first_line
          return if method_on_receiver_last_line?(node, base_receiver, :begin)

          node
        end

        def method_on_receiver_last_line?(node, base_receiver, type)
          return false unless base_receiver

          same_line?(node.loc.dot, base_receiver.source_range.end) && base_receiver.type?(type)
        end

        def get_dot_right_above(node)
          node.each_ancestor.find do |a|
            dot = a.loc.dot if a.loc?(:dot)
            next unless dot

            dot.line == node.loc.dot.line - 1 && dot.column == node.loc.dot.column
          end
        end

        def find_multiline_block_chain_node(node)
          return find_continuation_node(node) if node.block_node

          handle_descendant_block(node)
        end

        def find_continuation_node(node)
          receiver = node.receiver
          return receiver.send_node if single_line_block_receiver?(receiver)
          return unless receiver.call_type? && receiver.loc.dot
          return receiver if receiver.receiver.begin_type? && node.block_node.single_line?
          return unless receiver.loc.dot.line > receiver.receiver.last_line

          receiver
        end

        def single_line_block_receiver?(receiver)
          receiver.single_line? && receiver.any_block_type?
        end

        def handle_descendant_block(node)
          receiver = node.receiver
          return receiver.send_node if single_line_block_receiver?(receiver)

          block_node = node.each_descendant(:any_block).first
          return unless block_node&.multiline?

          receiver.call_type? ? receiver : block_node.parent
        end

        def first_call_has_a_dot(node)
          base = find_base_receiver(node)
          node = base.parent
          node = node.parent until node.loc?(:dot)
          node
        end

        def operation_rhs(node)
          operation_rhs = node.receiver.each_ancestor(:send).find do |rhs|
            operator_rhs?(rhs, node.receiver)
          end

          return unless operation_rhs

          yield operation_rhs.first_argument
        end

        def operator_rhs?(node, receiver)
          node.operator_method? && node.arguments? && within_node?(receiver, node.first_argument)
        end
      end
    end
  end
end
