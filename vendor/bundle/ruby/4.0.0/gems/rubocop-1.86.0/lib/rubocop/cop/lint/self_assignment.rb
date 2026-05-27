# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for self-assignments.
      #
      # @example
      #   # bad
      #   foo = foo
      #   foo, bar = foo, bar
      #   Foo = Foo
      #   hash['foo'] = hash['foo']
      #   obj.attr = obj.attr
      #
      #   # good
      #   foo = bar
      #   foo, bar = bar, foo
      #   Foo = Bar
      #   hash['foo'] = hash['bar']
      #   obj.attr = obj.attr2
      #
      #   # good (method calls possibly can return different results)
      #   hash[foo] = hash[foo]
      #
      # @example AllowRBSInlineAnnotation: false (default)
      #   # bad
      #   foo = foo #: Integer
      #   foo, bar = foo, bar #: Integer
      #   Foo = Foo #: Integer
      #   hash['foo'] = hash['foo'] #: Integer
      #   obj.attr = obj.attr #: Integer
      #
      # @example AllowRBSInlineAnnotation: true
      #   # good
      #   foo = foo #: Integer
      #   foo, bar = foo, bar #: Integer
      #   Foo = Foo #: Integer
      #   hash['foo'] = hash['foo'] #: Integer
      #   obj.attr = obj.attr #: Integer
      #
      class SelfAssignment < Base
        MSG = 'Self-assignment detected.'

        ASSIGNMENT_TYPE_TO_RHS_TYPE = {
          lvasgn: :lvar,
          ivasgn: :ivar,
          cvasgn: :cvar,
          gvasgn: :gvar
        }.freeze

        def on_send(node)
          return if allow_rbs_inline_annotation? && rbs_inline_annotation?(node.receiver)

          if node.method?(:[]=)
            handle_key_assignment(node)
          elsif node.assignment_method?
            handle_attribute_assignment(node) if node.arguments.size == 1
          end
        end
        alias on_csend on_send

        def on_lvasgn(node)
          return unless node.rhs
          return if allow_rbs_inline_annotation? && rbs_inline_annotation?(node.rhs)

          rhs_type = ASSIGNMENT_TYPE_TO_RHS_TYPE[node.type]

          add_offense(node) if node.rhs.type == rhs_type && node.rhs.source == node.lhs.to_s
        end
        alias on_ivasgn on_lvasgn
        alias on_cvasgn on_lvasgn
        alias on_gvasgn on_lvasgn

        def on_casgn(node)
          return unless node.rhs&.const_type?
          return if allow_rbs_inline_annotation? && rbs_inline_annotation?(node.rhs)

          add_offense(node) if node.namespace == node.rhs.namespace &&
                               node.short_name == node.rhs.short_name
        end

        def on_masgn(node)
          first_lhs = node.lhs.assignments.first
          return if allow_rbs_inline_annotation? && rbs_inline_annotation?(first_lhs)

          add_offense(node) if multiple_self_assignment?(node)
        end

        def on_or_asgn(node)
          return if allow_rbs_inline_annotation? && rbs_inline_annotation?(node.lhs)

          add_offense(node) if rhs_matches_lhs?(node.rhs, node.lhs)
        end
        alias on_and_asgn on_or_asgn

        private

        def multiple_self_assignment?(node)
          lhs = node.lhs
          rhs = node.rhs
          return false unless rhs.array_type?
          return false unless lhs.children.size == rhs.children.size

          lhs.children.zip(rhs.children).all? do |lhs_item, rhs_item|
            rhs_matches_lhs?(rhs_item, lhs_item)
          end
        end

        def rhs_matches_lhs?(rhs, lhs)
          rhs.type == ASSIGNMENT_TYPE_TO_RHS_TYPE[lhs.type] &&
            rhs.children.first == lhs.children.first
        end

        def handle_key_assignment(node)
          value_node = node.last_argument
          node_arguments = node.arguments[0...-1]

          if value_node.respond_to?(:method?) && value_node.method?(:[]) &&
             node.receiver == value_node.receiver &&
             node_arguments.none?(&:call_type?) &&
             node_arguments == value_node.arguments
            add_offense(node)
          end
        end

        def handle_attribute_assignment(node)
          first_argument = node.first_argument
          return unless first_argument.respond_to?(:arguments) && first_argument.arguments.empty?

          if first_argument.call_type? &&
             node.receiver == first_argument.receiver &&
             first_argument.method_name.to_s == node.method_name.to_s.delete_suffix('=')
            add_offense(node)
          end
        end

        def rbs_inline_annotation?(node)
          processed_source.ast_with_comments[node].any? { |comment| comment.text.start_with?('#:') }
        end

        def allow_rbs_inline_annotation?
          cop_config['AllowRBSInlineAnnotation']
        end
      end
    end
  end
end
