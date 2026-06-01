# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces consistent style for empty class definitions.
      #
      # This cop can enforce either a standard class definition or `Class.new`
      # for classes with no body.
      #
      # The supported styles are:
      #
      # * class_keyword (default) - prefer standard class definition over `Class.new`
      # * class_new - prefer `Class.new` over class definition
      #
      # One difference between the two styles is that the `Class.new` form does not make
      # the subclass name available to the base class's `inherited` callback.
      # For this reason, `EnforcedStyle: class_keyword` is set as the default style.
      # Class definitions without a superclass, which are not involved in inheritance,
      # are not detected. This ensures safe detection regardless of the applied style.
      # This avoids overlapping responsibilities with the `Lint/EmptyClass` cop.
      #
      # Use `AllowedParentClasses` to permit both styles for specific parent classes.
      # For example, adding `StandardError` allows both `Error = Class.new(StandardError)`
      # and `class Error < StandardError; end` regardless of the enforced style.
      #
      # @example EnforcedStyle: class_keyword (default)
      #   # bad
      #   FooError = Class.new(StandardError)
      #
      #   # okish
      #   class FooError < StandardError; end
      #
      #   # good
      #   class FooError < StandardError
      #   end
      #
      # @example EnforcedStyle: class_new
      #   # bad
      #   class FooError < StandardError
      #   end
      #
      #   # bad
      #   class FooError < StandardError; end
      #
      #   # good
      #   FooError = Class.new(StandardError)
      #
      # @example AllowedParentClasses: ['StandardError']
      #   # good - allowed regardless of EnforcedStyle
      #   FooError = Class.new(StandardError)
      #
      #   # good - allowed regardless of EnforcedStyle
      #   class FooError < StandardError
      #   end
      #
      class EmptyClassDefinition < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG_CLASS_KEYWORD =
          'Use the `class` keyword instead of `Class.new` to define an empty class.'
        MSG_CLASS_NEW = 'Use `Class.new` instead of the `class` keyword to define an empty class.'

        # @!method class_new_assignment(node)
        def_node_matcher :class_new_assignment, <<~PATTERN
          (casgn _ _ $(send (const _ :Class) :new _))
        PATTERN

        def on_casgn(node)
          return unless %i[class_keyword class_definition].include?(style)
          return unless (class_new_node = class_new_assignment(node))
          return if (arg = class_new_node.first_argument) && !arg.const_type?
          return if allowed_parent_class?(class_new_node.first_argument.source)

          add_offense(node, message: MSG_CLASS_KEYWORD) do |corrector|
            autocorrect_class_new(corrector, node, class_new_node)
          end
        end

        def on_class(node)
          return unless style == :class_new
          return unless node.parent_class
          return if (body = node.body) && !body.children.empty?
          return if allowed_parent_class?(node.parent_class.source)

          add_offense(node, message: MSG_CLASS_NEW) do |corrector|
            autocorrect_class_definition(corrector, node)
          end
        end

        private

        def allowed_parent_class?(parent_class_name)
          allowed_parent_classes.include?(parent_class_name)
        end

        def allowed_parent_classes
          cop_config.fetch('AllowedParentClasses', [])
        end

        def autocorrect_class_new(corrector, node, class_new_node)
          indent = ' ' * node.loc.column
          class_name = node.name
          parent_class_name = class_new_node.first_argument.source

          corrector.replace(node, "class #{class_name} < #{parent_class_name}\n#{indent}end")
        end

        def autocorrect_class_definition(corrector, node)
          class_name = node.identifier.source
          parent_class_name = node.parent_class.source

          corrector.replace(node, "#{class_name} = Class.new(#{parent_class_name})")
        end
      end
    end
  end
end
