# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Prefer symbol arguments over strings in `order` method.
      #
      # @safety
      #   Cop is unsafe because the receiver might not be an Active Record query.
      #
      # @example
      #   # bad
      #   User.order('name')
      #   User.order('name DESC')
      #
      #   # good
      #   User.order(:name)
      #   User.order(name: :desc)
      #
      class OrderArguments < Base
        extend AutoCorrector

        MSG = 'Prefer `%<prefer>s` instead.'

        RESTRICT_ON_SEND = %i[order].freeze

        def_node_matcher :string_order, <<~PATTERN
          (call _ :order (str $_value)+)
        PATTERN

        ORDER_EXPRESSION_REGEX = /\A(\w+) ?(asc|desc)?\z/i.freeze

        def on_send(node)
          return unless (current_expressions = string_order(node))
          return unless (preferred_expressions = replacement(current_expressions))

          offense_range = find_offense_range(node)
          add_offense(offense_range, message: format(MSG, prefer: preferred_expressions)) do |corrector|
            corrector.replace(offense_range, preferred_expressions)
          end
        end
        alias on_csend on_send

        private

        def find_offense_range(node)
          node.first_argument.source_range.join(node.last_argument.source_range)
        end

        def replacement(order_expressions)
          order_arguments = order_expressions.flat_map { |expr| expr.split(',') }
          order_arguments.map! { |arg| extract_column_and_direction(arg.strip) }

          return if order_arguments.any?(&:nil?)
          return if order_arguments.any? { |column_name, _| positional_column?(column_name) }

          convert_to_preferred_arguments(order_arguments).join(', ')
        end

        def convert_to_preferred_arguments(order_expressions)
          use_hash = false
          order_expressions.map do |column, direction|
            if direction == :asc && !use_hash
              ":#{column}"
            else
              use_hash = true
              "#{column}: :#{direction}"
            end
          end
        end

        def positional_column?(column_name)
          column_name.match?(/\A\d+\z/)
        end

        def extract_column_and_direction(order_expression)
          return unless (column, direction = ORDER_EXPRESSION_REGEX.match(order_expression)&.captures)

          [column.downcase, direction&.downcase&.to_sym || :asc]
        end
      end
    end
  end
end
