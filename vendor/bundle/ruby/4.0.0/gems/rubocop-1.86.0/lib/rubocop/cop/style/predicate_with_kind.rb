# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of `any?`, `all?`, `none?`, or `one?` with a block
      # containing only an `is_a?`, `kind_of?`, or `instance_of?` check, and
      # suggests using the predicate method with the class argument directly.
      #
      # @safety
      #   This cop is unsafe because `instance_of?` checks for an exact class
      #   match, while the pattern argument uses `===` which also matches
      #   subclasses. For `is_a?` and `kind_of?`, the behavior is equivalent.
      #
      # @example
      #   # bad
      #   array.any? { |x| x.is_a?(Integer) }
      #   array.all? { |x| x.kind_of?(String) }
      #   array.none? { |x| x.is_a?(Float) }
      #   array.one? { |x| x.instance_of?(Symbol) }
      #
      #   # good
      #   array.any?(Integer)
      #   array.all?(String)
      #   array.none?(Float)
      #   array.one?(Symbol)
      class PredicateWithKind < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` to `%<original>s` with a kind check.'
        RESTRICT_ON_SEND = %i[any? all? none? one?].freeze
        KIND_METHODS = %i[is_a? kind_of? instance_of?].to_set.freeze

        # @!method kind_check?(node)
        def_node_matcher :kind_check?, <<~PATTERN
          {
            (block call (args (arg $_)) $(send (lvar _) %KIND_METHODS _))
            (numblock call $1 $(send (lvar _) %KIND_METHODS _))
            (itblock call $_ $(send (lvar _) %KIND_METHODS _))
          }
        PATTERN

        # @!method kind_call?(node, name)
        def_node_matcher :kind_call?, <<~PATTERN
          (send (lvar %1) %KIND_METHODS _)
        PATTERN

        def on_send(node)
          return unless (block_node = node.block_node)
          return if block_node.body&.begin_type?
          return unless (kind_check_node = extract_send_node(block_node))

          klass = kind_check_node.first_argument
          replacement = "#{node.method_name}(#{klass.source})"

          register_offense(node, block_node, klass, replacement)
        end
        alias on_csend on_send

        private

        def extract_send_node(block_node)
          return unless (block_arg_name, kind_check_node = kind_check?(block_node))

          block_arg_name = :"_#{block_arg_name}" if block_node.numblock_type?
          block_arg_name = :it if block_node.type?(:itblock)

          kind_check_node if kind_call?(kind_check_node, block_arg_name)
        end

        def register_offense(node, block_node, klass, replacement)
          original = "#{node.method_name} { ... }"
          message = format(MSG, replacement: replacement, original: original)

          add_offense(block_node, message: message) do |corrector|
            range = range_between(node.loc.selector.begin_pos, block_node.loc.end.end_pos)
            corrector.replace(range, "#{node.method_name}(#{klass.source})")
          end
        end
      end
    end
  end
end
