# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant safe navigation calls.
      # Use cases where a constant, named in camel case for classes and modules is `nil` are rare,
      # and an offense is not detected when the receiver is a constant. The detection also applies
      # to `self`, and to literal receivers, except for `nil`.
      #
      # For all receivers, the `instance_of?`, `kind_of?`, `is_a?`, `eql?`, `respond_to?`,
      # and `equal?` methods are checked by default.
      # These are customizable with `AllowedMethods` option.
      #
      # The `AllowedMethods` option specifies nil-safe methods,
      # in other words, it is a method that is allowed to skip safe navigation.
      # Note that the `AllowedMethod` option is not an option that specifies methods
      # for which to suppress (allow) this cop's check.
      #
      # In the example below, the safe navigation operator (`&.`) is unnecessary
      # because `NilClass` has methods like `respond_to?` and `is_a?`.
      #
      # The `InferNonNilReceiver` option specifies whether to look into previous code
      # paths to infer if the receiver can't be nil. This check is unsafe because the receiver
      # can be redefined between the safe navigation call and previous regular method call.
      # It does the inference only in the current scope, e.g. within the same method definition etc.
      #
      # The `AdditionalNilMethods` option specifies additional custom methods which are
      # defined on `NilClass`. When `InferNonNilReceiver` is set, they are used to determine
      # whether the receiver can be nil.
      #
      # @safety
      #   This cop is unsafe, because autocorrection can change the return type of
      #   the expression. An offending expression that previously could return `nil`
      #   will be autocorrected to never return `nil`.
      #
      # @example
      #   # bad
      #   CamelCaseConst&.do_something
      #
      #   # good
      #   CamelCaseConst.do_something
      #
      #   # bad
      #   foo.to_s&.strip
      #   foo.to_i&.zero?
      #   foo.to_f&.zero?
      #   foo.to_a&.size
      #   foo.to_h&.size
      #
      #   # good
      #   foo.to_s.strip
      #   foo.to_i.zero?
      #   foo.to_f.zero?
      #   foo.to_a.size
      #   foo.to_h.size
      #
      #   # bad
      #   do_something if attrs&.respond_to?(:[])
      #
      #   # good
      #   do_something if attrs.respond_to?(:[])
      #
      #   # bad
      #   foo&.bar ? foo&.bar.baz : qux
      #
      #   # good
      #   foo&.bar ? foo.bar.baz : qux
      #
      #   # bad
      #   if foo&.bar
      #     foo&.bar.baz
      #   end
      #
      #   # good
      #   if foo&.bar
      #     foo.bar.baz
      #   end
      #
      #   # bad
      #   while node&.is_a?(BeginNode)
      #     node = node.parent
      #   end
      #
      #   # good
      #   while node.is_a?(BeginNode)
      #     node = node.parent
      #   end
      #
      #   # good - without `&.` this changes the return value for `nil`
      #   foo&.respond_to?(:to_a)
      #   foo&.respond_to?(:class)
      #
      #   # bad - for `nil`s conversion methods return default values for the type
      #   foo&.to_h || {}
      #   foo&.to_h { |k, v| [k, v] } || {}
      #   foo&.to_a || []
      #   foo&.to_i || 0
      #   foo&.to_f || 0.0
      #   foo&.to_s || ''
      #
      #   # good
      #   foo.to_h
      #   foo.to_h { |k, v| [k, v] }
      #   foo.to_a
      #   foo.to_i
      #   foo.to_f
      #   foo.to_s
      #
      #   # bad
      #   self&.foo
      #
      #   # good
      #   self.foo
      #
      # @example AllowedMethods: [nil_safe_method]
      #   # bad
      #   do_something if attrs&.nil_safe_method(:[])
      #
      #   # good
      #   do_something if attrs.nil_safe_method(:[])
      #   do_something if attrs&.not_nil_safe_method(:[])
      #
      # @example InferNonNilReceiver: false (default)
      #   # good
      #   foo.bar
      #   foo&.baz
      #
      # @example InferNonNilReceiver: true
      #   # bad
      #   foo.bar
      #   foo&.baz # would raise on previous line if `foo` is nil
      #
      #   # good
      #   foo.bar
      #   foo.baz
      #
      #   # bad
      #   if foo.condition?
      #     foo&.bar
      #   end
      #
      #   # good
      #   if foo.condition?
      #     foo.bar
      #   end
      #
      #   # good (different scopes)
      #   def method1
      #     foo.bar
      #   end
      #
      #   def method2
      #     foo&.bar
      #   end
      #
      # @example AdditionalNilMethods: [present?]
      #   # good
      #   foo.present?
      #   foo&.bar
      #
      class RedundantSafeNavigation < Base
        include AllowedMethods
        extend AutoCorrector

        MSG = 'Redundant safe navigation detected, use `.` instead.'
        MSG_LITERAL = 'Redundant safe navigation with default literal detected.'
        MSG_NON_NIL = 'Redundant safe navigation on non-nil receiver (detected by analyzing ' \
                      'previous code/method invocations).'

        NIL_METHODS = nil.methods.to_set.freeze

        SNAKE_CASE = /\A[[:digit:][:upper:]_]+\z/.freeze

        GUARANTEED_INSTANCE_METHODS = %i[to_s to_i to_f to_a to_h].freeze

        # @!method respond_to_nil_method?(node)
        def_node_matcher :respond_to_nil_method?, <<~PATTERN
          (csend _ :respond_to? (sym %NIL_METHODS))
        PATTERN

        # @!method conversion_with_default?(node)
        def_node_matcher :conversion_with_default?, <<~PATTERN
          {
            (or $(csend _ :to_h) (hash))
            (or (block $(csend _ :to_h) ...) (hash))
            (or $(csend _ :to_a) (array))
            (or $(csend _ :to_i) (int 0))
            (or $(csend _ :to_f) (float 0.0))
            (or $(csend _ :to_s) (str empty?))
          }
        PATTERN

        # rubocop:disable Metrics/AbcSize
        def on_csend(node)
          range = node.loc.dot

          if infer_non_nil_receiver?
            checker = Lint::Utils::NilReceiverChecker.new(node.receiver, additional_nil_methods)

            if checker.cant_be_nil?
              add_offense(range, message: MSG_NON_NIL) { |corrector| corrector.replace(range, '.') }
              return
            end
          end

          unless assume_receiver_instance_exists?(node.receiver)
            return if !guaranteed_instance?(node.receiver) && !check?(node)
            return if respond_to_nil_method?(node)
          end

          add_offense(range) { |corrector| corrector.replace(range, '.') }
        end
        # rubocop:enable Metrics/AbcSize

        # rubocop:disable Metrics/AbcSize
        def on_or(node)
          conversion_with_default?(node) do |send_node|
            range = send_node.loc.dot.begin.join(node.source_range.end)

            add_offense(range, message: MSG_LITERAL) do |corrector|
              corrector.replace(send_node.loc.dot, '.')

              range_with_default = node.lhs.source_range.end.begin.join(node.source_range.end)
              corrector.remove(range_with_default)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        private

        def assume_receiver_instance_exists?(receiver)
          return true if receiver.const_type? && !receiver.short_name.match?(SNAKE_CASE)

          receiver.self_type? || (receiver.literal? && !receiver.nil_type?)
        end

        def guaranteed_instance?(node)
          receiver = if node.any_block_type?
                       node.send_node
                     else
                       node
                     end
          return false unless receiver.send_type?

          GUARANTEED_INSTANCE_METHODS.include?(receiver.method_name)
        end

        def check?(node)
          return false unless allowed_method?(node.method_name)

          parent = node.parent
          return false unless parent

          condition?(parent, node) ||
            parent.operator_keyword? ||
            (parent.send_type? && parent.negation_method?)
        end

        def condition?(parent, node)
          (parent.conditional? || parent.post_condition_loop?) && parent.condition == node
        end

        def infer_non_nil_receiver?
          cop_config['InferNonNilReceiver']
        end

        def additional_nil_methods
          @additional_nil_methods ||=
            Array(cop_config.fetch('AdditionalNilMethods', []).map(&:to_sym))
        end
      end
    end
  end
end
