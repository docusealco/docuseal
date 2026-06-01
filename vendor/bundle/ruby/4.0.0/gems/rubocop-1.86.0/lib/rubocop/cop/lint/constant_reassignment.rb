# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for constant reassignments.
      #
      # Emulates Ruby's runtime warning "already initialized constant X"
      # when a constant is reassigned in the same file and namespace.
      #
      # The cop tracks constants defined via `NAME = value` syntax as well as
      # class/module keyword definitions. It detects reassignment when a constant
      # is first defined one way and then redefined using the `NAME = value` syntax.
      #
      # The cop cannot catch all offenses, like, for example, when a constant
      # is reassigned in another file, or when using metaprogramming (`Module#const_set`).
      #
      # The cop only takes into account constants assigned in a "simple" way: directly
      # inside class/module definition, or within another constant. Other type of assignments
      # (e.g., inside a conditional) are disregarded.
      #
      # The cop also tracks constant removal using `Module#remove_const` with symbol
      # or string argument.
      #
      # @example
      #   # bad
      #   X = :foo
      #   X = :bar
      #
      #   # bad
      #   class A
      #     X = :foo
      #     X = :bar
      #   end
      #
      #   # bad
      #   module A
      #     X = :foo
      #     X = :bar
      #   end
      #
      #   # bad
      #   class FooError < StandardError; end
      #   FooError = Class.new(RuntimeError)
      #
      #   # bad
      #   module M; end
      #   M = 1
      #
      #   # good - keep only one assignment
      #   X = :bar
      #
      #   class A
      #     X = :bar
      #   end
      #
      #   module A
      #     X = :bar
      #   end
      #
      #   # good - use OR assignment
      #   X = :foo
      #   X ||= :bar
      #
      #   # good - use conditional assignment
      #   X = :foo
      #   X = :bar unless defined?(X)
      #
      #   # good - remove the assigned constant first
      #   class A
      #     X = :foo
      #     remove_const :X
      #     X = :bar
      #   end
      #
      class ConstantReassignment < Base
        MSG = 'Constant `%<constant>s` is already assigned in this namespace.'

        RESTRICT_ON_SEND = %i[remove_const].freeze

        # @!method remove_constant(node)
        def_node_matcher :remove_constant, <<~PATTERN
          (send {nil? self} :remove_const
            ({sym str} $_))
        PATTERN

        def on_class(node)
          return unless unconditional_definition?(node)

          constant_definitions[definition_name(node)] ||= :class
        end

        def on_module(node)
          return unless unconditional_definition?(node)

          constant_definitions[definition_name(node)] ||= :module
        end

        def on_casgn(node)
          return unless fixed_constant_path?(node)
          return unless simple_assignment?(node)

          name = fully_qualified_constant_name(node)
          return constant_definitions[name] = :casgn unless constant_definitions.key?(name)

          add_offense(node, message: format(MSG, constant: constant_display_name(node)))
        end

        def on_send(node)
          constant = remove_constant(node)

          return unless constant

          namespaces = ancestor_namespaces(node)

          return if namespaces.none?

          constant_definitions.delete(fully_qualified_name_for(namespaces, constant))
        end

        private

        def fixed_constant_path?(node)
          node.each_path.all? { |path| path.type?(:cbase, :const, :self) }
        end

        def simple_assignment?(node)
          node.ancestors.all? do |ancestor|
            return true if ancestor.type?(:module, :class)

            ancestor.begin_type? || ancestor.literal? || ancestor.casgn_type? ||
              ancestor.type?(:masgn, :mlhs) || freeze_method?(ancestor)
          end
        end

        def freeze_method?(node)
          node.send_type? && node.method?(:freeze)
        end

        def fully_qualified_constant_name(node)
          if node.absolute?
            namespace = node.namespace.const_type? ? node.namespace.source : nil

            "#{namespace}::#{node.name}"
          else
            constant_namespaces = ancestor_namespaces(node) + constant_namespaces(node)

            fully_qualified_name_for(constant_namespaces, node.name)
          end
        end

        def fully_qualified_name_for(namespaces, constant)
          ['', *namespaces, constant].join('::')
        end

        def constant_display_name(node)
          [*constant_namespaces(node), node.name].join('::')
        end

        def constant_namespaces(node)
          node.each_path.select(&:const_type?).map(&:short_name)
        end

        def ancestor_namespaces(node)
          node
            .each_ancestor(:class, :module)
            .map { |ancestor| ancestor.identifier.short_name }
            .reverse
        end

        def unconditional_definition?(node)
          node.each_ancestor.all? do |ancestor|
            ancestor.type?(:begin, :module, :class)
          end
        end

        def definition_name(node)
          identifier = node.identifier

          if identifier.namespace&.cbase_type?
            fully_qualified_name_for([], identifier.short_name)
          else
            namespaces = ancestor_namespaces(node) + identifier_namespaces(identifier)
            fully_qualified_name_for(namespaces, identifier.short_name)
          end
        end

        def identifier_namespaces(identifier)
          identifier.each_path.select(&:const_type?).map(&:short_name)
        end

        def constant_definitions
          @constant_definitions ||= {}
        end
      end
    end
  end
end
