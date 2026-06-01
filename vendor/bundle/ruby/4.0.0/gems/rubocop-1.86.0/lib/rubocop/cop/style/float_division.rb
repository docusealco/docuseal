# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for division with integers coerced to floats.
      # It is recommended to either always use `fdiv` or coerce one side only.
      # This cop also provides other options for code consistency.
      #
      # For `Regexp.last_match` and nth reference (e.g., `$1`), it assumes that the value
      # is a string matched by a regular expression, and allows conversion with `#to_f`.
      #
      # @safety
      #   This cop is unsafe, because if the operand variable is a string object
      #   then `#to_f` will be removed and an error will occur.
      #
      #   [source,ruby]
      #   ----
      #   a = '1.2'
      #   b = '3.4'
      #   a.to_f / b.to_f # Both `to_f` calls are required here
      #   ----
      #
      # @example EnforcedStyle: single_coerce (default)
      #   # bad
      #   a.to_f / b.to_f
      #
      #   # good
      #   a.to_f / b
      #   a / b.to_f
      #
      # @example EnforcedStyle: left_coerce
      #   # bad
      #   a / b.to_f
      #   a.to_f / b.to_f
      #
      #   # good
      #   a.to_f / b
      #
      # @example EnforcedStyle: right_coerce
      #   # bad
      #   a.to_f / b
      #   a.to_f / b.to_f
      #
      #   # good
      #   a / b.to_f
      #
      # @example EnforcedStyle: fdiv
      #   # bad
      #   a / b.to_f
      #   a.to_f / b
      #   a.to_f / b.to_f
      #
      #   # good
      #   a.fdiv(b)
      class FloatDivision < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MESSAGES = {
          left_coerce: 'Prefer using `.to_f` on the left side.',
          right_coerce: 'Prefer using `.to_f` on the right side.',
          single_coerce: 'Prefer using `.to_f` on one side only.',
          fdiv: 'Prefer using `fdiv` for float divisions.'
        }.freeze

        RESTRICT_ON_SEND = %i[/].freeze

        # @!method right_coerce?(node)
        def_node_matcher :right_coerce?, <<~PATTERN
          (send _ :/ #to_f_method?)
        PATTERN
        # @!method left_coerce?(node)
        def_node_matcher :left_coerce?, <<~PATTERN
          (send #to_f_method? :/ _)
        PATTERN
        # @!method both_coerce?(node)
        def_node_matcher :both_coerce?, <<~PATTERN
          (send #to_f_method? :/ #to_f_method?)
        PATTERN
        # @!method any_coerce?(node)
        def_node_matcher :any_coerce?, <<~PATTERN
          {(send _ :/ #to_f_method?) (send #to_f_method? :/ _)}
        PATTERN
        # @!method to_f_method?(node)
        def_node_matcher :to_f_method?, <<~PATTERN
          (send !nil? :to_f)
        PATTERN

        # @!method regexp_last_match?(node)
        def_node_matcher :regexp_last_match?, <<~PATTERN
          {
            (send (const {nil? cbase} :Regexp) :last_match int)
            (:nth_ref _)
          }
        PATTERN

        def on_send(node)
          return unless offense_condition?(node)

          add_offense(node) do |corrector|
            case style
            when :left_coerce, :single_coerce
              add_to_f_method(corrector, node.receiver)
              remove_to_f_method(corrector, node.first_argument)
            when :right_coerce
              remove_to_f_method(corrector, node.receiver)
              add_to_f_method(corrector, node.first_argument)
            when :fdiv
              correct_from_slash_to_fdiv(corrector, node, node.receiver, node.first_argument)
            end
          end
        end

        private

        def offense_condition?(node)
          return false if regexp_last_match?(node.receiver.receiver) ||
                          regexp_last_match?(node.first_argument.receiver)

          case style
          when :left_coerce
            right_coerce?(node)
          when :right_coerce
            left_coerce?(node)
          when :single_coerce
            both_coerce?(node)
          when :fdiv
            any_coerce?(node)
          else
            false
          end
        end

        def message(_node)
          MESSAGES[style]
        end

        def add_to_f_method(corrector, node)
          corrector.insert_after(node, '.to_f') unless node.send_type? && node.method?(:to_f)
        end

        def remove_to_f_method(corrector, send_node)
          corrector.remove(send_node.loc.dot)
          corrector.remove(send_node.loc.selector)
        end

        def correct_from_slash_to_fdiv(corrector, node, receiver, argument)
          receiver_source = extract_receiver_source(receiver)
          argument_source = extract_receiver_source(argument)

          if argument.respond_to?(:parenthesized?) && !argument.parenthesized?
            argument_source = "(#{argument_source})"
          end

          corrector.replace(node, "#{receiver_source}.fdiv#{argument_source}")
        end

        def extract_receiver_source(node)
          if node.send_type? && node.method?(:to_f)
            node.receiver.source
          else
            node.source
          end
        end
      end
    end
  end
end
