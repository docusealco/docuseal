# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks that `Rails.env` is compared using `.production?`-like
      # methods instead of equality against a string or symbol.
      #
      # @example
      #   # bad
      #   Rails.env == 'production'
      #   Rails.env.to_sym == :production
      #
      #   # bad, always returns false
      #   Rails.env == :test
      #
      #   # good
      #   Rails.env.production?
      class EnvironmentComparison < Base
        extend AutoCorrector

        MSG = 'Favor `%<prefer>s` over `%<source>s`.'

        SYM_MSG = 'Do not compare `Rails.env` with a symbol, it will always evaluate to `false`.'

        RESTRICT_ON_SEND = %i[== !=].freeze

        def_node_matcher :comparing_env_with_rails_env_on_lhs?, <<~PATTERN
          {
            (send
              (send (const {nil? cbase} :Rails) :env)
              {:== :!=}
              $str
            )
            (send
              (send (send (const {nil? cbase} :Rails) :env) :to_sym)
              {:== :!=}
              $sym
            )
          }
        PATTERN

        def_node_matcher :comparing_env_with_rails_env_on_rhs?, <<~PATTERN
          {
            (send
              $str
              {:== :!=}
              (send (const {nil? cbase} :Rails) :env)
            )
            (send
              $sym
              {:== :!=}
              (send (send (const {nil? cbase} :Rails) :env) :to_sym)
            )
          }
        PATTERN

        def_node_matcher :comparing_sym_env_with_rails_env_on_lhs?, <<~PATTERN
          (send
            (send (const {nil? cbase} :Rails) :env)
            {:== :!=}
            $sym
          )
        PATTERN

        def_node_matcher :comparing_sym_env_with_rails_env_on_rhs?, <<~PATTERN
          (send
            $sym
            {:== :!=}
            (send (const {nil? cbase} :Rails) :env)
          )
        PATTERN

        def on_send(node)
          check_env_comparison_with_rails_env(node)
          check_sym_env_comparison_with_rails_env(node)
        end

        private

        def check_env_comparison_with_rails_env(node)
          return unless comparing_env_with_rails_env_on_lhs?(node) || comparing_env_with_rails_env_on_rhs?(node)

          replacement = build_predicate_method(node)
          message = format(MSG, prefer: replacement, source: node.source)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end

        def check_sym_env_comparison_with_rails_env(node)
          return unless comparing_sym_env_with_rails_env_on_lhs?(node) || comparing_sym_env_with_rails_env_on_rhs?(node)

          add_offense(node, message: SYM_MSG) do |corrector|
            replacement = build_predicate_method(node)
            corrector.replace(node, replacement)
          end
        end

        def build_predicate_method(node)
          bang = node.method?(:!=) ? '!' : ''

          receiver, argument = extract_receiver_and_argument(node)
          receiver = receiver.receiver if receiver.method?(:to_sym)

          "#{bang}#{receiver.source}.#{argument.value}?"
        end

        def extract_receiver_and_argument(node)
          if rails_env_on_lhs?(node)
            [node.receiver, node.first_argument]
          else
            [node.first_argument, node.receiver]
          end
        end

        def rails_env_on_lhs?(node)
          comparing_env_with_rails_env_on_lhs?(node) || comparing_sym_env_with_rails_env_on_lhs?(node)
        end
      end
    end
  end
end
