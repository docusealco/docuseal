# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Identifies usages of `arr[arr.length - n]`, `arr[arr.size - n]`, or
      # `arr[arr.count - n]` and suggests to change them to use `arr[-n]` instead.
      # Also handles range patterns like `arr[0..(arr.length - n)]`.
      #
      # The cop recognizes preserving methods (`sort`, `reverse`, `shuffle`, `rotate`)
      # and their combinations, allowing safe replacement when the receiver matches.
      # It works with variables, instance variables, class variables, and constants.
      #
      # @example
      #   # bad
      #   arr[arr.count - 2]
      #   arr[0..(arr.length - 2)]
      #   arr[0...(arr.length - 4)]
      #   arr.sort[arr.reverse.length - 2]
      #   arr.sort.reverse[arr.sort.size - 2]
      #
      #   # good
      #   arr[-2]
      #   arr[0..-2]
      #   arr[0...-4]
      #   arr.sort[-2]
      #   arr.sort.reverse[-2]
      #
      class NegativeArrayIndex < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Use `%<receiver>s[-%<index>s]` instead of `%<current>s`.'
        MSG_RANGE = 'Use `%<receiver>s[%<start>s%<range_op>s-%<index>s]` instead of `%<current>s`.'
        RESTRICT_ON_SEND = %i[[]].freeze

        LENGTH_METHODS = %i[length size count].freeze

        PRESERVING_METHODS = %i[sort reverse shuffle rotate].freeze

        # @!method length_subtraction?(node)
        def_node_matcher :length_subtraction?, <<~PATTERN
          (send
            (send $_ {:length :size :count}) :-
            (int $_))
        PATTERN

        def on_send(node)
          return if node.arguments.empty?

          index_arg = node.first_argument
          range_node = extract_range_from_begin(index_arg)
          if range_with_length_subtraction?(range_node, node.receiver)
            receiver = node.receiver.source
            return handle_range_pattern(receiver, range_node, index_arg)
          end

          handle_simple_index_pattern(node, index_arg)
        end

        alias on_csend on_send

        private

        def handle_simple_index_pattern(node, index_arg)
          length_receiver, negative_index = length_subtraction?(index_arg)

          return unless negative_index&.positive?
          return unless receivers_match?(length_receiver, node.receiver)

          add_offense_for_subtraction(node, index_arg, negative_index)
        end

        def extract_range_from_begin(node)
          node.begin_type? ? node.children.first : node
        end

        def extract_inner_end(node)
          node.children.size == 1 ? node.children.first : node
        end

        def add_offense_for_subtraction(node, index_arg, negative_index)
          receiver = node.receiver.source
          offense_range = index_arg.source_range
          current = "#{receiver}[#{index_arg.source}]"

          message = format(MSG, receiver: receiver, index: negative_index, current: current)

          add_offense(offense_range, message: message) do |corrector|
            corrector.replace(offense_range, "-#{negative_index}")
          end
        end

        def range_with_length_subtraction?(range_node, array_receiver)
          return false unless range_node.range_type?

          range_end = range_node.end
          range_start = range_node.begin
          return false unless range_end && range_start

          return false unless preserving_method?(range_start)

          inner_end = extract_inner_end(range_end)
          length_receiver, negative_index = length_subtraction?(inner_end)

          return false unless negative_index&.positive?

          receivers_match_strict?(length_receiver, array_receiver)
        end

        def handle_range_pattern(receiver, range_node, index_arg)
          range_end = range_node.end
          inner_end = extract_inner_end(range_end)
          _length_receiver, negative_index = length_subtraction?(inner_end)

          message, replacement = build_range_offense_data(
            receiver, range_node, range_end, inner_end, negative_index, index_arg
          )

          add_offense(range_end, message: message) do |corrector|
            corrector.replace(index_arg, replacement)
          end
        end

        # rubocop:disable Metrics/ParameterLists
        def build_range_offense_data(receiver, range_node, range_end, inner_end, negative_index,
                                     index_arg)
          range_op = range_node.erange_type? ? '...' : '..'
          range_start = range_node.begin.source

          range_without_parens =
            build_range_without_parens(range_start, range_op, range_end, inner_end)
          current_source = build_current_source(receiver, range_without_parens, index_arg)
          start, index = format_range_message_parts(range_start, negative_index, index_arg)

          message = build_message_for_range(receiver, start, range_op, index, current_source)
          replacement = build_replacement_string(range_start, range_op, negative_index, index_arg)

          [message, replacement]
        end
        # rubocop:enable Metrics/ParameterLists

        def format_range_message_parts(range_start, negative_index, index_arg)
          has_parentheses = index_arg.begin_type?
          start = has_parentheses ? "(#{range_start}" : range_start
          index = has_parentheses ? "#{negative_index})" : negative_index

          [start, index]
        end

        def build_message_for_range(receiver, start, range_op, index, current)
          format(
            MSG_RANGE,
            receiver: receiver, start: start, range_op: range_op, index: index, current: current
          )
        end

        def build_replacement_string(range_start, range_op, negative_index, index_arg)
          has_parentheses = index_arg.begin_type?

          if has_parentheses
            "(#{range_start}#{range_op}-#{negative_index})"
          else
            "#{range_start}#{range_op}-#{negative_index}"
          end
        end

        def build_current_source(receiver, range_without_parens, index_arg)
          has_parentheses = index_arg.begin_type?

          if has_parentheses
            "#{receiver}[(#{range_without_parens})]"
          else
            "#{receiver}[#{range_without_parens}]"
          end
        end

        def build_range_without_parens(range_start, range_op, range_end, inner_end)
          end_expression = range_end.begin_type? ? range_end.source : inner_end.source

          "#{range_start}#{range_op}#{end_expression}"
        end

        def receivers_match?(length_receiver, array_receiver)
          return array_receiver.self_type? unless length_receiver

          unless preserving_method?(array_receiver) && preserving_method?(length_receiver)
            return false
          end
          return true if length_receiver.source == array_receiver.source

          !extract_base_receiver(array_receiver).nil?
        end

        def receivers_match_strict?(length_receiver, array_receiver)
          preserving_method?(array_receiver) &&
            length_receiver.source == array_receiver.source
        end

        def extract_base_receiver(node)
          receiver = node.receiver

          return nil unless receiver
          return receiver unless receiver.receiver

          extract_base_receiver(receiver)
        end

        def preserving_method?(node)
          return true if node.receiver.nil?

          method_name = node.method_name
          return false unless PRESERVING_METHODS.include?(method_name)

          preserving_method?(node.receiver)
        end
      end
    end
  end
end
