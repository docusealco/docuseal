# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for usage of `Rails.env.development? || Rails.env.test?` which
      # can be replaced with `Rails.env.local?`, introduced in Rails 7.1.
      #
      # @example
      #
      #   # bad
      #   Rails.env.development? || Rails.env.test?
      #
      #   # good
      #   Rails.env.local?
      #
      class EnvLocal < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `Rails.env.local?` instead.'
        MSG_NEGATED = 'Use `!Rails.env.local?` instead.'
        LOCAL_ENVIRONMENTS = %i[development? test?].to_set.freeze

        minimum_target_rails_version 7.1

        # @!method rails_env_local?(node)
        def_node_matcher :rails_env_local?, <<~PATTERN
          (send (send (const {cbase nil? } :Rails) :env) $%LOCAL_ENVIRONMENTS)
        PATTERN

        # @!method not_rails_env_local?(node)
        def_node_matcher :not_rails_env_local?, <<~PATTERN
          (send #rails_env_local? :!)
        PATTERN

        def on_or(node)
          lhs, rhs = *node.children
          return unless rails_env_local?(rhs)

          nodes = [rhs]

          if rails_env_local?(lhs)
            nodes << lhs
          elsif lhs.or_type? && rails_env_local?(lhs.rhs)
            nodes << lhs.rhs
          end

          return unless environments(nodes).to_set == LOCAL_ENVIRONMENTS

          range = offense_range(nodes)
          add_offense(range) do |corrector|
            corrector.replace(range, 'Rails.env.local?')
          end
        end

        def on_and(node)
          lhs, rhs = *node.children
          return unless not_rails_env_local?(rhs)

          nodes = [rhs]

          if not_rails_env_local?(lhs)
            nodes << lhs
          elsif lhs.operator_keyword? && not_rails_env_local?(lhs.rhs)
            nodes << lhs.rhs
          end

          return unless environments(nodes).to_set == LOCAL_ENVIRONMENTS

          range = offense_range(nodes)
          add_offense(range, message: MSG_NEGATED) do |corrector|
            corrector.replace(range, '!Rails.env.local?')
          end
        end

        private

        def environments(nodes)
          if nodes[0].method?(:!)
            nodes.map { |node| node.receiver.method_name }
          else
            nodes.map(&:method_name)
          end
        end

        def offense_range(nodes)
          nodes[1].source_range.begin.join(nodes[0].source_range.end)
        end
      end
    end
  end
end
