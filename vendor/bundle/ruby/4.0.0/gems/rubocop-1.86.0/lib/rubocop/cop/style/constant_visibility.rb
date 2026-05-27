# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks that constants defined in classes and modules have
      # an explicit visibility declaration. By default, Ruby makes all class-
      # and module constants public, which litters the public API of the
      # class or module. Explicitly declaring a visibility makes intent more
      # clear, and prevents outside actors from touching private state.
      #
      # @example
      #
      #   # bad
      #   class Foo
      #     BAR = 42
      #     BAZ = 43
      #   end
      #
      #   # good
      #   class Foo
      #     BAR = 42
      #     private_constant :BAR
      #
      #     BAZ = 43
      #     public_constant :BAZ
      #   end
      #
      # @example IgnoreModules: false (default)
      #   # bad
      #   class Foo
      #     MyClass = Struct.new
      #   end
      #
      #   # good
      #   class Foo
      #     MyClass = Struct.new
      #     public_constant :MyClass
      #   end
      #
      # @example IgnoreModules: true
      #   # good
      #   class Foo
      #     MyClass = Struct.new
      #   end
      #
      class ConstantVisibility < Base
        MSG = 'Explicitly make `%<constant_name>s` public or private using ' \
              'either `#public_constant` or `#private_constant`.'

        # @!method visibility_declaration_for(node)
        def_node_matcher :visibility_declaration_for, <<~PATTERN
          (send nil? {:public_constant :private_constant} $...)
        PATTERN

        def on_casgn(node)
          return unless class_or_module_scope?(node)
          return if visibility_declaration?(node)
          return if ignore_modules? && module?(node)

          add_offense(node, message: format(MSG, constant_name: node.name))
        end

        private

        def ignore_modules?
          cop_config.fetch('IgnoreModules', false)
        end

        def module?(node)
          node.expression.class_constructor?
        end

        def class_or_module_scope?(node)
          return false unless node.parent

          case node.parent.type
          when :begin
            class_or_module_scope?(node.parent)
          when :class, :module
            true
          end
        end

        # rubocop:disable Metrics/AbcSize
        def visibility_declaration?(node)
          node.parent.each_child_node(:send).any? do |child|
            next false unless (arguments = visibility_declaration_for(child))

            arguments = arguments.first.children.first.to_a if arguments.first&.splat_type?
            constant_values = arguments.map do |argument|
              argument.value.to_sym if argument.respond_to?(:value)
            end

            constant_values.include?(node.name)
          end
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
