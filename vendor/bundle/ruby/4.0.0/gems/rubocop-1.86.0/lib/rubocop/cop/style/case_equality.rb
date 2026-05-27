# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the case equality operator (`===`).
      # The `===` operator has different behavior depending on the
      # receiver and its use outside of `case`/`when` is confusing.
      # Prefer more explicit alternatives like `is_a?`, `include?`,
      # or `match?`.
      #
      # If `AllowOnConstant` option is enabled, the cop will ignore violations when the receiver of
      # the case equality operator is a constant.
      #
      # If `AllowOnSelfClass` option is enabled, the cop will ignore violations when the receiver of
      # the case equality operator is `self.class`. Note intermediate variables are not accepted.
      #
      # NOTE: Regexp case equality (`/regexp/ === var`) is allowed because changing it to
      # `/regexp/.match?(var)` needs to take into account `Regexp.last_match?`, `$~`, `$1`, etc.
      # This potentially incompatible transformation is handled by `Performance/RegexpMatch` cop.
      #
      # @example
      #   # bad
      #   (1..100) === 7
      #
      #   # good
      #   (1..100).include?(7)
      #
      # @example AllowOnConstant: false (default)
      #   # bad
      #   Array === something
      #
      #   # good
      #   something.is_a?(Array)
      #
      # @example AllowOnConstant: true
      #   # good
      #   Array === something
      #   something.is_a?(Array)
      #
      # @example AllowOnSelfClass: false (default)
      #   # bad
      #   self.class === something
      #
      # @example AllowOnSelfClass: true
      #   # good
      #   self.class === something
      #
      class CaseEquality < Base
        extend AutoCorrector

        MSG = 'Avoid the use of the case equality operator `===`.'
        RESTRICT_ON_SEND = %i[===].freeze

        # @!method case_equality?(node)
        def_node_matcher :case_equality?, '(send $#offending_receiver? :=== $_)'

        # @!method self_class?(node)
        def_node_matcher :self_class?, '(send (self) :class)'

        def on_send(node)
          case_equality?(node) do |lhs, rhs|
            return if lhs.regexp_type? || (lhs.const_type? && !lhs.module_name?)

            add_offense(node.loc.selector) do |corrector|
              replacement = replacement(lhs, rhs)
              corrector.replace(node, replacement) if replacement
            end
          end
        end

        private

        def offending_receiver?(node)
          return false if node&.const_type? && cop_config.fetch('AllowOnConstant', false)
          return false if self_class?(node) && cop_config.fetch('AllowOnSelfClass', false)

          true
        end

        def replacement(lhs, rhs)
          case lhs.type
          when :begin
            begin_replacement(lhs, rhs)
          when :const
            const_replacement(lhs, rhs)
          when :send
            send_replacement(lhs, rhs)
          end
        end

        def begin_replacement(lhs, rhs)
          return unless lhs.children.first&.range_type?

          "#{lhs.source}.include?(#{rhs.source})"
        end

        def const_replacement(lhs, rhs)
          "#{rhs.source}.is_a?(#{lhs.source})"
        end

        def send_replacement(lhs, rhs)
          return unless self_class?(lhs)

          "#{rhs.source}.is_a?(#{lhs.source})"
        end
      end
    end
  end
end
