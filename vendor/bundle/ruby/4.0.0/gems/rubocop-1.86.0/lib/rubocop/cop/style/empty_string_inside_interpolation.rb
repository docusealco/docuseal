# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for empty strings being assigned inside string interpolation.
      #
      # Empty strings are a meaningless outcome inside of string interpolation, so we remove them.
      # Alternatively, when configured to do so, we prioritise using empty strings.
      #
      # While this cop would also apply to variables that are only going to be used as strings,
      # RuboCop can't detect that, so we only check inside of string interpolation.
      #
      # @example EnforcedStyle: trailing_conditional (default)
      #   # bad
      #   "#{condition ? 'foo' : ''}"
      #
      #   # good
      #   "#{'foo' if condition}"
      #
      #   # bad
      #   "#{condition ? '' : 'foo'}"
      #
      #   # good
      #   "#{'foo' unless condition}"
      #
      # @example EnforcedStyle: ternary
      #   # bad
      #   "#{'foo' if condition}"
      #
      #   # good
      #   "#{condition ? 'foo' : ''}"
      #
      #   # bad
      #   "#{'foo' unless condition}"
      #
      #   # good
      #   "#{condition ? '' : 'foo'}"
      #
      class EmptyStringInsideInterpolation < Base
        include ConfigurableEnforcedStyle
        include Interpolation
        extend AutoCorrector

        MSG_TRAILING_CONDITIONAL = 'Do not use trailing conditionals in string interpolation.'
        MSG_TERNARY = 'Do not return empty strings in string interpolation.'

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
        def on_interpolation(node)
          node.each_child_node(:if) do |child_node|
            if style == :trailing_conditional
              if empty_if_outcome?(child_node)
                ternary_style_autocorrect(child_node, child_node.else_branch.source, 'unless')
              end

              if empty_else_outcome?(child_node)
                ternary_style_autocorrect(child_node, child_node.if_branch.source, 'if')
              end
            elsif style == :ternary
              next unless child_node.modifier_form?

              ternary_component = if child_node.unless?
                                    "'' : #{child_node.if_branch.source}"
                                  else
                                    "#{child_node.if_branch.source} : ''"
                                  end

              add_offense(node, message: MSG_TRAILING_CONDITIONAL) do |corrector|
                corrector.replace(node, "\#{#{child_node.condition.source} ? #{ternary_component}}")
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

        private

        def empty_if_outcome?(node)
          empty_branch_outcome?(node.if_branch)
        end

        def empty_else_outcome?(node)
          empty_branch_outcome?(node.else_branch)
        end

        def empty_branch_outcome?(branch)
          return false unless branch

          branch.nil_type? || (branch.str_type? && branch.value.empty?)
        end

        def ternary_style_autocorrect(node, outcome, condition)
          add_offense(node, message: MSG_TERNARY) do |corrector|
            corrector.replace(node, "#{outcome} #{condition} #{node.condition.source}")
          end
        end
      end
    end
  end
end
