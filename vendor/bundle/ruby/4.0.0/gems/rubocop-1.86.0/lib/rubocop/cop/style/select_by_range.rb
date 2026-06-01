# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for places where a subset of an Enumerable (array,
      # range, set, etc.; see note below) is calculated based on a range
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
      #   array.select { |x| x.between?(1, 10) }
      #   array.select { |x| (1..10).cover?(x) }
      #   array.select { |x| (1..10).include?(x) }
      #
      #   # bad (reject)
      #   array.reject { |x| x.between?(1, 10) }
      #
      #   # bad (find or detect)
      #   array.find { |x| x.between?(1, 10) }
      #   array.detect { |x| (1..10).cover?(x) }
      #
      #   # bad (negative form)
      #   array.reject { |x| !x.between?(1, 10) }
      #   array.find { |x| !(1..10).cover?(x) }
      #
      #   # good
      #   array.grep(1..10)
      #   array.grep_v(1..10)
      #   array.grep(1..10).first
      #   array.grep_v(1..10).first
      class SelectByRange < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Prefer `%<replacement>s` to `%<original_method>s` with a range check.'
        RESTRICT_ON_SEND = %i[select filter find_all reject find detect].freeze
        SELECT_METHODS = %i[select filter find_all].freeze
        FIND_METHODS = %i[find detect].freeze

        # @!method range_check?(node)
        # Matches: x.between?(min, max) or (min..max).cover?(x) or (min..max).include?(x)
        def_node_matcher :range_check?, <<~PATTERN
          {
            (block call (args (arg $_)) ${(send (lvar _) :between? _ _)})
            (block call (args (arg $_)) ${(send {range (begin range)} {:cover? :include?} (lvar _))})
            (block call (args (arg $_)) ${(send (send (lvar _) :between? _ _) :!)})
            (block call (args (arg $_)) ${(send (send {range (begin range)} {:cover? :include?} (lvar _)) :!)})
            (block call (args (arg $_)) ${(send (begin (send (lvar _) :between? _ _)) :!)})
            (block call (args (arg $_)) ${(send (begin (send {range (begin range)} {:cover? :include?} (lvar _))) :!)})
            (numblock call $1 ${(send (lvar _) :between? _ _)})
            (numblock call $1 ${(send {range (begin range)} {:cover? :include?} (lvar _))})
            (numblock call $1 ${(send (send (lvar _) :between? _ _) :!)})
            (numblock call $1 ${(send (send {range (begin range)} {:cover? :include?} (lvar _)) :!)})
            (numblock call $1 ${(send (begin (send (lvar _) :between? _ _)) :!)})
            (numblock call $1 ${(send (begin (send {range (begin range)} {:cover? :include?} (lvar _))) :!)})
            (itblock call $_ ${(send (lvar _) :between? _ _)})
            (itblock call $_ ${(send {range (begin range)} {:cover? :include?} (lvar _))})
            (itblock call $_ ${(send (send (lvar _) :between? _ _) :!)})
            (itblock call $_ ${(send (send {range (begin range)} {:cover? :include?} (lvar _)) :!)})
            (itblock call $_ ${(send (begin (send (lvar _) :between? _ _)) :!)})
            (itblock call $_ ${(send (begin (send {range (begin range)} {:cover? :include?} (lvar _))) :!)})
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

        # @!method between_call?(node, name)
        def_node_matcher :between_call?, <<~PATTERN
          (send (lvar %1) :between? _ _)
        PATTERN

        # @!method range_cover_call?(node, name)
        def_node_matcher :range_cover_call?, <<~PATTERN
          (send {range (begin range)} {:cover? :include?} (lvar %1))
        PATTERN

        def on_send(node)
          return unless (block_node = node.block_node)
          return if block_node.body&.begin_type?
          return if receiver_allowed?(block_node.receiver)
          return unless (range_check_send_node = extract_send_node(block_node))

          replacement = replacement(range_check_send_node, node)
          range_literal = find_range(range_check_send_node)

          register_offense(node, block_node, range_literal, replacement)
        end
        alias on_csend on_send

        private

        def receiver_allowed?(node)
          return false unless node

          node.hash_type? || creates_hash?(node) || env_const?(node)
        end

        def replacement(range_check_send_node, node)
          negated = negated?(range_check_send_node)
          method_name = node.method_name

          if SELECT_METHODS.include?(method_name)
            negated ? 'grep_v' : 'grep'
          elsif FIND_METHODS.include?(method_name)
            negated ? 'grep_v(...).first' : 'grep(...).first'
          else # reject
            negated ? 'grep' : 'grep_v'
          end
        end

        def register_offense(node, block_node, range_literal, replacement)
          message = format(MSG, replacement: replacement, original_method: node.method_name)

          add_offense(block_node, message: message) do |corrector|
            if range_literal
              range = range_between(node.loc.selector.begin_pos, block_node.loc.end.end_pos)
              grep_method = replacement.include?('grep_v') ? 'grep_v' : 'grep'
              suffix = replacement.include?('.first') ? '.first' : ''
              corrector.replace(range, "#{grep_method}(#{range_literal})#{suffix}")
            end
          end
        end

        def extract_send_node(block_node)
          return unless (block_arg_name, range_check_send_node = range_check?(block_node))

          block_arg_name = :"_#{block_arg_name}" if block_node.numblock_type?
          block_arg_name = :it if block_node.type?(:itblock)

          inner_node = unwrap_negation(range_check_send_node)

          range_check_send_node if calls_lvar_in_range_check?(inner_node, block_arg_name)
        end

        def calls_lvar_in_range_check?(node, block_arg_name)
          between_call?(node, block_arg_name) || range_cover_call?(node, block_arg_name)
        end

        def negated?(range_check_send_node)
          range_check_send_node.send_type? && range_check_send_node.method?(:!)
        end

        def unwrap_negation(node)
          if node.send_type? && node.method?(:!)
            receiver = node.receiver
            receiver = receiver.children.first if receiver.begin_type?
            receiver
          else
            node
          end
        end

        def find_range(node)
          inner = unwrap_negation(node)

          if inner.method?(:between?)
            # x.between?(min, max) -> min..max
            min = inner.first_argument.source
            max = inner.arguments[1].source
            "#{min}..#{max}"
          else
            # (min..max).cover?(x) or (min..max).include?(x)
            receiver = inner.receiver
            # Unwrap begin node from parentheses
            receiver = receiver.children.first if receiver.begin_type?
            receiver.source
          end
        end
      end
    end
  end
end
