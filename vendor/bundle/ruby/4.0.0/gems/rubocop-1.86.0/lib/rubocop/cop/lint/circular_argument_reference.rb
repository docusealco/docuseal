# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for circular argument references in optional keyword
      # arguments and optional ordinal arguments.
      #
      # NOTE: This syntax was made invalid on Ruby 2.7 - Ruby 3.3 but is allowed
      # again since Ruby 3.4.
      #
      # @example
      #
      #   # bad
      #   def bake(pie: pie)
      #     pie.heat_up
      #   end
      #
      #   # good
      #   def bake(pie:)
      #     pie.refrigerate
      #   end
      #
      #   # good
      #   def bake(pie: self.pie)
      #     pie.feed_to(user)
      #   end
      #
      #   # bad
      #   def cook(dry_ingredients = dry_ingredients)
      #     dry_ingredients.reduce(&:+)
      #   end
      #
      #   # good
      #   def cook(dry_ingredients = self.dry_ingredients)
      #     dry_ingredients.combine
      #   end
      #
      #   # bad
      #   def foo(pie = pie = pie)
      #     pie.heat_up
      #   end
      #
      #   # good
      #   def foo(pie)
      #     pie.heat_up
      #   end
      #
      #   # bad
      #   def foo(pie = cake = pie)
      #     [pie, cake].each(&:heat_up)
      #   end
      #
      #   # good
      #   def foo(cake = pie)
      #     [pie, cake].each(&:heat_up)
      #   end
      class CircularArgumentReference < Base
        extend TargetRubyVersion

        MSG = 'Circular argument reference - `%<arg_name>s`.'

        def on_kwoptarg(node)
          check_for_circular_argument_references(*node)
        end

        def on_optarg(node)
          check_for_circular_argument_references(*node)
        end

        private

        def check_for_circular_argument_references(arg_name, arg_value)
          if arg_value.lvar_type? && arg_value.to_a == [arg_name]
            add_offense(arg_value, message: format(MSG, arg_name: arg_name))

            return
          end

          check_assignment_chain(arg_name, arg_value)
        end

        # rubocop:disable Metrics/AbcSize
        def check_assignment_chain(arg_name, node)
          return unless node.lvasgn_type?

          seen_variables = Set[]
          current_node = node

          while current_node.lvasgn_type?
            seen_variables << current_node.children.first if current_node.lvasgn_type?
            current_node = current_node.children.last
          end

          return unless current_node.lvar_type?

          variable_node = current_node.children.first
          return unless seen_variables.include?(variable_node) || variable_node == arg_name

          add_offense(current_node, message: format(MSG, arg_name: arg_name))
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
