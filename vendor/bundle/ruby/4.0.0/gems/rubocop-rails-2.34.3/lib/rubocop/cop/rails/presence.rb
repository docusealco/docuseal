# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks code that can be written more easily using
      # `Object#presence` defined by Active Support.
      #
      # @example
      #   # bad
      #   a.present? ? a : nil
      #
      #   # bad
      #   !a.present? ? nil : a
      #
      #   # bad
      #   a.blank? ? nil : a
      #
      #   # bad
      #   !a.blank? ? a : nil
      #
      #   # good
      #   a.presence
      #
      # @example
      #   # bad
      #   a.present? ? a : b
      #
      #   # bad
      #   !a.present? ? b : a
      #
      #   # bad
      #   a.blank? ? b : a
      #
      #   # bad
      #   !a.blank? ? a : b
      #
      #   # good
      #   a.presence || b
      #
      # @example
      #   # bad
      #   a.present? ? a.foo : nil
      #
      #   # bad
      #   !a.present? ? nil : a.foo
      #
      #   # bad
      #   a.blank? ? nil : a.foo
      #
      #   # bad
      #   !a.blank? ? a.foo : nil
      #
      #   # good
      #   a.presence&.foo
      #
      #   # good
      #   a.present? ? a[1] : nil
      #
      #   # good
      #   a[:key] = value if a.present?
      #
      #   # good
      #   a.present? ? a > 1 : nil
      #   a <= 0 if a.present?
      class Presence < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `%<prefer>s` instead of `%<current>s`.'
        INDEX_ACCESS_METHODS = %i[[] []=].freeze

        def_node_matcher :redundant_receiver_and_other, <<~PATTERN
          {
            (if
              {(send $_recv :blank?) (send (send $_recv :present?) :!)}
              $!begin
              _recv
            )
            (if
              {(send $_recv :present?) (send (send $_recv :blank?) :!)}
              _recv
              $!begin
            )
          }
        PATTERN

        def_node_matcher :redundant_receiver_and_chain, <<~PATTERN
          {
            (if
              {(send $_recv :blank?) (send (send $_recv :present?) :!)}
              {nil? nil_type?}
              $(send _recv ...)
            )
            (if
              {(send $_recv :present?) (send (send $_recv :blank?) :!)}
              $(send _recv ...)
              {nil? nil_type?}
            )
          }
        PATTERN

        def on_if(node)
          return if ignore_if_node?(node)

          redundant_receiver_and_other(node) do |receiver, other|
            return if ignore_other_node?(other) || receiver.nil?

            register_offense(node, receiver, other)
          end

          redundant_receiver_and_chain(node) do |receiver, chain|
            return if ignore_chain_node?(chain) || receiver.nil?

            register_chain_offense(node, receiver, chain)
          end
        end

        private

        def register_offense(node, receiver, other)
          replacement = replacement(receiver, other, node.left_sibling)
          add_offense(node, message: message(node, replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def register_chain_offense(node, receiver, chain)
          replacement = chain_replacement(receiver, chain, node.left_sibling)
          add_offense(node, message: message(node, replacement)) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def ignore_if_node?(node)
          node.elsif?
        end

        def ignore_other_node?(node)
          node&.type?(:if, :rescue, :while)
        end

        def ignore_chain_node?(node)
          index_access_method?(node) || node.assignment? || node.arithmetic_operation? || node.comparison_method?
        end

        def message(node, replacement)
          prefer  = replacement.gsub(/^\s*|\n/, '')
          current = current(node).gsub(/^\s*|\n/, '')
          format(MSG, prefer: prefer, current: current)
        end

        def current(node)
          if !node.ternary? && node.source.include?("\n")
            "#{node.loc.keyword.with(end_pos: node.condition.loc.selector.end_pos).source} ... end"
          else
            node.source.gsub(/\n\s*/, ' ')
          end
        end

        def replacement(receiver, other, left_sibling)
          or_source = if other&.send_type?
                        build_source_for_or_method(other)
                      elsif other.nil? || other.nil_type?
                        ''
                      else
                        " || #{other.source}"
                      end

          replaced = "#{receiver.source}.presence#{or_source}"
          left_sibling ? "(#{replaced})" : replaced
        end

        def build_source_for_or_method(other)
          if other.parenthesized? || other.method?('[]') || other.arithmetic_operation? || !other.arguments?
            " || #{other.source}"
          else
            method = method_range(other).source
            arguments = other.arguments.map(&:source).join(', ')

            " || #{method}(#{arguments})"
          end
        end

        def method_range(node)
          range_between(node.source_range.begin_pos, node.first_argument.source_range.begin_pos - 1)
        end

        def chain_replacement(receiver, chain, left_sibling)
          replaced = "#{receiver.source}.presence&.#{chain.method_name}"
          replaced += "(#{chain.arguments.map(&:source).join(', ')})" if chain.arguments?
          left_sibling ? "(#{replaced})" : replaced
        end

        def index_access_method?(node)
          INDEX_ACCESS_METHODS.include?(node.method_name)
        end
      end
    end
  end
end
