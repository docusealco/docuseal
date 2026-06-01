# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for consecutive `#start_with?` or `#end_with?` calls.
      # These methods accept multiple arguments, so in some cases like when
      # they are separated by `||`, they can be combined into a single method call.
      #
      # `IncludeActiveSupportAliases` configuration option is used to check for
      # `starts_with?` and `ends_with?`. These methods are defined by Active Support.
      #
      # @example
      #   # bad
      #   str.start_with?("a") || str.start_with?(Some::CONST)
      #   str.start_with?("a", "b") || str.start_with?("c")
      #   !str.start_with?(foo) && !str.start_with?(bar)
      #   str.end_with?(var1) || str.end_with?(var2)
      #
      #   # good
      #   str.start_with?("a", Some::CONST)
      #   str.start_with?("a", "b", "c")
      #   !str.start_with?(foo, bar)
      #   str.end_with?(var1, var2)
      #
      # @example IncludeActiveSupportAliases: false (default)
      #   # good
      #   str.starts_with?("a", "b") || str.starts_with?("c")
      #   str.ends_with?(var1) || str.ends_with?(var2)
      #
      #   str.starts_with?("a", "b", "c")
      #   str.ends_with?(var1, var2)
      #
      # @example IncludeActiveSupportAliases: true
      #   # bad
      #   str.starts_with?("a", "b") || str.starts_with?("c")
      #   str.ends_with?(var1) || str.ends_with?(var2)
      #
      #   # good
      #   str.starts_with?("a", "b", "c")
      #   str.ends_with?(var1, var2)
      #
      class DoubleStartEndWith < Base
        extend AutoCorrector

        MSG = 'Use `%<replacement>s` instead of `%<original_code>s`.'

        METHODS = %i[start_with? end_with?].to_set
        METHODS_WITH_ACTIVE_SUPPORT = %i[start_with? starts_with? end_with? ends_with?].to_set

        def on_or(node)
          two_start_end_with_calls(node, methods_to_check: methods) do |*matched|
            check(node, *matched)
          end
        end

        def on_and(node)
          two_start_end_with_calls_negated(node, methods_to_check: methods) do |*matched|
            check(node, *matched)
          end
        end

        private

        def check(node, receiver, method, first_call_args, second_call_args)
          return unless receiver && second_call_args.all?(&:pure?)

          combined_args = combine_args(first_call_args, second_call_args)

          add_offense(node, message: message(node, receiver, method, combined_args)) do |corrector|
            autocorrect(corrector, first_call_args, second_call_args, combined_args)
          end
        end

        def autocorrect(corrector, first_call_args, second_call_args, combined_args)
          first_argument = first_call_args.first.source_range
          last_argument = second_call_args.last.source_range
          range = first_argument.join(last_argument)

          corrector.replace(range, combined_args)
        end

        def methods
          if check_for_active_support_aliases?
            METHODS_WITH_ACTIVE_SUPPORT
          else
            METHODS
          end
        end

        def message(node, receiver, method, combined_args)
          parent = receiver.parent
          grandparent = parent.parent
          dot = parent.send_type? ? '.' : '&.'
          bang = grandparent.send_type? && grandparent.prefix_bang? ? '!' : ''
          replacement = "#{bang}#{receiver.source}#{dot}#{method}(#{combined_args})"
          format(MSG, replacement: replacement, original_code: node.source)
        end

        def combine_args(first_call_args, second_call_args)
          (first_call_args + second_call_args).map(&:source).join(', ')
        end

        def check_for_active_support_aliases?
          cop_config['IncludeActiveSupportAliases']
        end

        def_node_matcher :two_start_end_with_calls, <<~PATTERN
          (or
            (call $_recv [%methods_to_check $_method] $...)
            (call _recv _method $...))
        PATTERN

        def_node_matcher :two_start_end_with_calls_negated, <<~PATTERN
          (and
            (send (call $_recv [%methods_to_check $_method] $...) :!)
            (send (call _recv _method $...) :!))
        PATTERN
      end
    end
  end
end
