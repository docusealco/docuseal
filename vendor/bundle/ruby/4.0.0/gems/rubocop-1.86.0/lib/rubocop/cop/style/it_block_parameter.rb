# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for blocks with one argument where `it` block parameter can be used.
      #
      # It provides four `EnforcedStyle` options:
      #
      # 1. `allow_single_line` (default) ... Always uses the `it` block parameter in a single line.
      # 2. `only_numbered_parameters` ... Detects only numbered block parameters.
      # 3. `always` ... Always uses the `it` block parameter.
      # 4. `disallow` ... Disallows the `it` block parameter.
      #
      # A single numbered parameter is detected when `allow_single_line`,
      # `only_numbered_parameters`, or `always`.
      #
      # @example EnforcedStyle: allow_single_line (default)
      #   # bad
      #   block do
      #     do_something(it)
      #   end
      #   block { do_something(_1) }
      #
      #   # good
      #   block { do_something(it) }
      #   block { |named_param| do_something(named_param) }
      #
      # @example EnforcedStyle: only_numbered_parameters
      #   # bad
      #   block { do_something(_1) }
      #
      #   # good
      #   block { do_something(it) }
      #   block { |named_param| do_something(named_param) }
      #
      # @example EnforcedStyle: always
      #   # bad
      #   block { do_something(_1) }
      #   block { |named_param| do_something(named_param) }
      #
      #   # good
      #   block { do_something(it) }
      #
      # @example EnforcedStyle: disallow
      #   # bad
      #   block { do_something(it) }
      #
      #   # good
      #   block { do_something(_1) }
      #   block { |named_param| do_something(named_param) }
      #
      class ItBlockParameter < Base
        include ConfigurableEnforcedStyle
        extend TargetRubyVersion
        extend AutoCorrector

        MSG_USE_IT_PARAMETER = 'Use `it` block parameter.'
        MSG_AVOID_IT_PARAMETER = 'Avoid using `it` block parameter.'
        MSG_AVOID_IT_PARAMETER_MULTILINE = 'Avoid using `it` block parameter for multi-line blocks.'

        minimum_target_ruby_version 3.4

        def on_block(node)
          return unless style == :always
          return unless node.arguments.one?

          # `restarg`, `kwrestarg`, `blockarg` nodes can return early.
          return unless node.first_argument.arg_type?

          variables = find_block_variables(node, node.first_argument.source)

          variables.each do |variable|
            add_offense(variable, message: MSG_USE_IT_PARAMETER) do |corrector|
              corrector.remove(node.arguments)
              corrector.replace(variable, 'it')
            end
          end
        end

        def on_numblock(node)
          return if style == :disallow
          return unless node.children[1] == 1

          variables = find_block_variables(node, '_1')

          variables.each do |variable|
            add_offense(variable, message: MSG_USE_IT_PARAMETER) do |corrector|
              corrector.replace(variable, 'it')
            end
          end
        end

        def on_itblock(node)
          case style
          when :allow_single_line
            return if node.single_line?

            add_offense(node, message: MSG_AVOID_IT_PARAMETER_MULTILINE)
          when :disallow
            variables = find_block_variables(node, 'it')

            variables.each do |variable|
              add_offense(variable, message: MSG_AVOID_IT_PARAMETER)
            end
          end
        end

        private

        def find_block_variables(node, block_argument_name)
          return [] unless node.body

          node.body.each_descendant(:lvar).select do |descendant|
            descendant.source == block_argument_name
          end
        end
      end
    end
  end
end
