# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for places where a subset of an Enumerable (array,
      # range, set, etc.; see note below) is calculated based on a class type
      # check, and suggests `grep` or `grep_v` instead.
      #
      # NOTE: Hashes do not behave as you may expect with `grep`, which
      # means that `hash.grep` is not equivalent to `hash.select`. Although
      # RuboCop is limited by static analysis, this cop attempts to avoid
      # registering an offense when the receiver is a hash (hash literal,
      # `Hash.new`, `Hash#[]`, or `to_h`/`to_hash`).
      #
      # @safety
      #   Autocorrection is marked as unsafe because the cop cannot guarantee
      #   that the receiver is actually an array by static analysis, so the
      #   correction may not be actually equivalent.
      #
      # @example
      #   # bad (select or find_all)
      #   array.select { |x| x.is_a?(Foo) }
      #   array.select { |x| x.kind_of?(Foo) }
      #
      #   # bad (reject)
      #   array.reject { |x| x.is_a?(Foo) }
      #
      #   # bad (negative form)
      #   array.reject { |x| !x.is_a?(Foo) }
      #
      #   # good
      #   array.grep(Foo)
      #   array.grep_v(Foo)
      class SelectByKind < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` to `%<original_method>s` with a kind check.'
        RESTRICT_ON_SEND = %i[select filter find_all reject].freeze
        SELECT_METHODS = %i[select filter find_all].freeze
        CLASS_CHECK_METHODS = %i[is_a? kind_of?].to_set.freeze

        # @!method class_check?(node)
        def_node_matcher :class_check?, <<~PATTERN
          {
            (block call (args (arg $_)) ${(send (lvar _) %CLASS_CHECK_METHODS _)})
            (block call (args (arg $_)) ${(send (send (lvar _) %CLASS_CHECK_METHODS _) :!)})
            (numblock call $1 ${(send (lvar _) %CLASS_CHECK_METHODS _)})
            (numblock call $1 ${(send (send (lvar _) %CLASS_CHECK_METHODS _) :!)})
            (itblock call $_ ${(send (lvar _) %CLASS_CHECK_METHODS _)})
            (itblock call $_ ${(send (send (lvar _) %CLASS_CHECK_METHODS _) :!)})
          }
        PATTERN

        # Returns true if a node appears to return a hash
        # @!method creates_hash?(node)
        def_node_matcher :creates_hash?, <<~PATTERN
          {
            (call (const _ :Hash) {:new :[]} ...)
            (block (call (const _ :Hash) :new ...) ...)
            (call _ { :to_h :to_hash } ...)
          }
        PATTERN

        # @!method env_const?(node)
        def_node_matcher :env_const?, <<~PATTERN
          (const {nil? cbase} :ENV)
        PATTERN

        # @!method calls_lvar?(node, name)
        def_node_matcher :calls_lvar?, <<~PATTERN
          (send (lvar %1) %CLASS_CHECK_METHODS _)
        PATTERN

        # @!method negated_calls_lvar?(node, name)
        def_node_matcher :negated_calls_lvar?, <<~PATTERN
          (send (send (lvar %1) %CLASS_CHECK_METHODS _) :!)
        PATTERN

        def on_send(node)
          return unless (block_node = node.block_node)
          return if block_node.body&.begin_type?
          return if receiver_allowed?(block_node.receiver)
          return unless (class_check_send_node = extract_send_node(block_node))

          replacement = replacement(class_check_send_node, node)
          class_constant = find_class_constant(class_check_send_node)

          register_offense(node, block_node, class_constant, replacement)
        end
        alias on_csend on_send

        private

        def receiver_allowed?(node)
          return false unless node

          node.hash_type? || creates_hash?(node) || env_const?(node)
        end

        def replacement(class_check_send_node, node)
          negated = negated?(class_check_send_node)

          method_name = node.method_name

          if SELECT_METHODS.include?(method_name)
            negated ? 'grep_v' : 'grep'
          else # reject
            negated ? 'grep' : 'grep_v'
          end
        end

        def register_offense(node, block_node, class_constant, replacement)
          message = format(MSG, replacement: replacement, original_method: node.method_name)

          add_offense(block_node, message: message) do |corrector|
            if class_constant
              range = range_between(node.loc.selector.begin_pos, block_node.loc.end.end_pos)
              corrector.replace(range, "#{replacement}(#{class_constant.source})")
            end
          end
        end

        def extract_send_node(block_node)
          return unless (block_arg_name, class_check_send_node = class_check?(block_node))

          block_arg_name = :"_#{block_arg_name}" if block_node.numblock_type?
          block_arg_name = :it if block_node.type?(:itblock)

          inner_node = unwrap_negation(class_check_send_node)

          if calls_lvar?(inner_node, block_arg_name) ||
             negated_calls_lvar?(class_check_send_node, block_arg_name)
            class_check_send_node
          end
        end

        def negated?(class_check_send_node)
          class_check_send_node.send_type? && class_check_send_node.method?(:!)
        end

        def unwrap_negation(node)
          if node.send_type? && node.method?(:!)
            node.receiver
          else
            node
          end
        end

        def find_class_constant(node)
          inner_node = unwrap_negation(node)
          inner_node.first_argument if inner_node.send_type?
        end
      end
    end
  end
end
