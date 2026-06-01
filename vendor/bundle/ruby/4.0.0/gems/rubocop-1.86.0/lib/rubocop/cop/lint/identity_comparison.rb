# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Prefer `equal?` over `==` when comparing `object_id`.
      #
      # `Object#equal?` is provided to compare objects for identity, and in contrast
      # `Object#==` is provided for the purpose of doing value comparison.
      #
      # @example
      #   # bad
      #   foo.object_id == bar.object_id
      #   foo.object_id != baz.object_id
      #
      #   # good
      #   foo.equal?(bar)
      #   !foo.equal?(baz)
      #
      class IdentityComparison < Base
        extend AutoCorrector

        MSG = 'Use `%<bang>sequal?` instead of `%<comparison_method>s` when comparing `object_id`.'
        RESTRICT_ON_SEND = %i[== !=].freeze

        # @!method object_id_comparison(node)
        def_node_matcher :object_id_comparison, <<~PATTERN
          (send
            (send
              _lhs_receiver :object_id) ${:== :!=}
            (send
              _rhs_receiver :object_id))
        PATTERN

        def on_send(node)
          return unless (comparison_method = object_id_comparison(node))

          bang = comparison_method == :== ? '' : '!'
          add_offense(node,
                      message: format(MSG, comparison_method: comparison_method,
                                           bang: bang)) do |corrector|
            receiver = node.receiver.receiver
            argument = node.first_argument.receiver
            return unless receiver && argument

            replacement = "#{bang}#{receiver.source}.equal?(#{argument.source})"

            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
