# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for the use of `Kernel#eval` and `Binding#eval` with
      # dynamic strings as arguments. Evaluating non-literal strings
      # can enable code injection attacks and makes it difficult to
      # reason about what code will actually be executed.
      #
      # Calls to `eval` with literal strings are not flagged by this cop,
      # as they do not pose the same injection risk.
      #
      # @example
      #
      #   # bad
      #   eval(something)
      #   binding.eval(something)
      #   Kernel.eval(something)
      #
      #   # good - use safer alternatives
      #   obj.public_send(method_name)
      #   obj.send(method_name, *args)
      #
      #   # good - literal strings are allowed
      #   eval("1 + 1")
      #   binding.eval("foo")
      class Eval < Base
        MSG = 'The use of `eval` is a serious security risk.'
        RESTRICT_ON_SEND = %i[eval].freeze

        # @!method eval?(node)
        def_node_matcher :eval?, <<~PATTERN
          (send {nil? (send nil? :binding) (const {cbase nil?} :Kernel)} :eval $!str ...)
        PATTERN

        def on_send(node)
          eval?(node) do |code|
            return if code.dstr_type? && code.recursive_literal?

            add_offense(node.loc.selector)
          end
        end
      end
    end
  end
end
