# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for useless OR (`||` and `or`) expressions.
      #
      # Some methods always return a truthy value, even when called
      # on `nil` (e.g. `nil.to_i` evaluates to `0`). Therefore, OR expressions
      # appended after these methods will never evaluate.
      #
      # @safety
      #   As shown in the examples below, there are generally two possible ways to correct the
      #   offense, but this cop's autocorrection always chooses the option that preserves the
      #   current behavior. While this does not change how the code behaves, that option is not
      #   necessarily the appropriate fix in every situation. For this reason, the autocorrection
      #   provided by this cop is considered unsafe.
      #
      # @example
      #
      #   # bad
      #   x.to_a || fallback
      #   x.to_c || fallback
      #   x.to_d || fallback
      #   x.to_i || fallback
      #   x.to_f || fallback
      #   x.to_h || fallback
      #   x.to_r || fallback
      #   x.to_s || fallback
      #   x.to_sym || fallback
      #   x.intern || fallback
      #   x.inspect || fallback
      #   x.hash || fallback
      #   x.object_id || fallback
      #   x.__id__ || fallback
      #
      #   x.to_s or fallback
      #
      #   # good - if fallback is same as return value of method called on nil
      #   x.to_a # nil.to_a returns []
      #   x.to_c # nil.to_c returns (0+0i)
      #   x.to_d # nil.to_d returns 0.0
      #   x.to_i # nil.to_i returns 0
      #   x.to_f # nil.to_f returns 0.0
      #   x.to_h # nil.to_h returns {}
      #   x.to_r # nil.to_r returns (0/1)
      #   x.to_s # nil.to_s returns ''
      #   x.to_sym # nil.to_sym raises an error
      #   x.intern # nil.intern raises an error
      #   x.inspect # nil.inspect returns "nil"
      #   x.hash # nil.hash returns an Integer
      #   x.object_id # nil.object_id returns an Integer
      #   x.__id__ # nil.object_id returns an Integer
      #
      #   # good - if the intention is not to call the method on nil
      #   x&.to_a || fallback
      #   x&.to_c || fallback
      #   x&.to_d || fallback
      #   x&.to_i || fallback
      #   x&.to_f || fallback
      #   x&.to_h || fallback
      #   x&.to_r || fallback
      #   x&.to_s || fallback
      #   x&.to_sym || fallback
      #   x&.intern || fallback
      #   x&.inspect || fallback
      #   x&.hash || fallback
      #   x&.object_id || fallback
      #   x&.__id__ || fallback
      #
      #   x&.to_s or fallback
      #
      class UselessOr < Base
        extend AutoCorrector

        MSG = '`%<rhs>s` will never evaluate because `%<lhs>s` always returns a truthy value.'

        TRUTHY_RETURN_VALUE_METHODS = Set[:to_a, :to_c, :to_d, :to_i, :to_f, :to_h, :to_r,
                                          :to_s, :to_sym, :intern, :inspect, :hash, :object_id,
                                          :__id__].freeze

        # @!method truthy_return_value_method?(node)
        def_node_matcher :truthy_return_value_method?, <<~PATTERN
          (send _ %TRUTHY_RETURN_VALUE_METHODS)
        PATTERN

        def on_or(node)
          if truthy_return_value_method?(node.lhs)
            report_offense(node, node.lhs)
          elsif truthy_return_value_method?(node.rhs)
            parent = node.parent
            parent = parent.parent if parent&.begin_type?

            report_offense(parent, node.rhs) if parent&.or_type?
          end
        end

        private

        def report_offense(or_node, truthy_node)
          add_offense(
            or_node.loc.operator.join(or_node.rhs.source_range),
            message: format(MSG, lhs: truthy_node.source, rhs: or_node.rhs.source)
          ) do |corrector|
            corrector.replace(or_node, or_node.lhs.source)
          end
        end
      end
    end
  end
end
