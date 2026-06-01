# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # In Ruby 3.1, `Array#intersect?` has been added.
      #
      # This cop identifies places where:
      #
      # * `(array1 & array2).any?`
      # * `(array1.intersection(array2)).any?`
      # * `array1.any? { |elem| array2.member?(elem) }`
      # * `(array1 & array2).count > 0`
      # * `(array1 & array2).size > 0`
      #
      # can be replaced with `array1.intersect?(array2)`.
      #
      # `array1.intersect?(array2)` is faster and more readable.
      #
      # In cases like the following, compatibility is not ensured,
      # so it will not be detected when using block argument.
      #
      # [source,ruby]
      # ----
      # ([1] & [1,2]).any? { |x| false }    # => false
      # [1].intersect?([1,2]) { |x| false } # => true
      # ----
      #
      # NOTE: Although `Array#intersection` can take zero or multiple arguments,
      # only cases where exactly one argument is provided can be replaced with
      # `Array#intersect?` and are handled by this cop.
      #
      # @safety
      #   This cop cannot guarantee that `array1` and `array2` are
      #   actually arrays while method `intersect?` is for arrays only.
      #
      # @example
      #   # bad
      #   (array1 & array2).any?
      #   (array1 & array2).empty?
      #   (array1 & array2).none?
      #
      #   # bad
      #   array1.intersection(array2).any?
      #   array1.intersection(array2).empty?
      #   array1.intersection(array2).none?
      #
      #   # bad
      #   array1.any? { |elem| array2.member?(elem) }
      #   array1.none? { |elem| array2.member?(elem) }
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      #
      #   # bad
      #   (array1 & array2).count > 0
      #   (array1 & array2).count.positive?
      #   (array1 & array2).count != 0
      #
      #   (array1 & array2).count == 0
      #   (array1 & array2).count.zero?
      #
      #   # good
      #   array1.intersect?(array2)
      #
      #   !array1.intersect?(array2)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #   # good
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #   # bad
      #   (array1 & array2).present?
      #   (array1 & array2).blank?
      #
      #   # good
      #   array1.intersect?(array2)
      #   !array1.intersect?(array2)
      class ArrayIntersect < Base
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 3.1

        PREDICATES = %i[any? empty? none?].to_set.freeze
        ACTIVE_SUPPORT_PREDICATES = (PREDICATES + %i[present? blank?]).freeze

        ARRAY_SIZE_METHODS = %i[count length size].to_set.freeze

        # @!method bad_intersection_check?(node, predicates)
        def_node_matcher :bad_intersection_check?, <<~PATTERN
          $(call
            {
              (begin (send $_ :& $_))
              (call $!nil? :intersection $_)
            }
            $%1
          )
        PATTERN

        # @!method intersection_size_check?(node, predicates)
        def_node_matcher :intersection_size_check?, <<~PATTERN
          (call
            $(call
              {
                (begin (send $_ :& $_))
                (call $!nil? :intersection $_)
              }
              %ARRAY_SIZE_METHODS
            )
            {$:> (int 0) | $:positive? | $:!= (int 0) | $:== (int 0) | $:zero?}
          )
        PATTERN

        # @!method any_none_block_intersection(node)
        def_node_matcher :any_none_block_intersection, <<~PATTERN
          {
            (block
              (call $_receiver ${:any? :none?})
              (args (arg _key))
              (send $_argument :member? (lvar _key))
            )
            (numblock
              (call $_receiver ${:any? :none?}) 1
              (send $_argument :member? (lvar :_1))
            )
            (itblock
              (call $_receiver ${:any? :none?}) :it
              (send $_argument :member? (lvar :it))
            )
          }
        PATTERN

        MSG = 'Use `%<replacement>s` instead of `%<existing>s`.'
        STRAIGHT_METHODS = %i[present? any? > positive? !=].freeze
        NEGATED_METHODS = %i[blank? empty? none? == zero?].freeze
        RESTRICT_ON_SEND = (STRAIGHT_METHODS + NEGATED_METHODS).freeze

        def on_send(node)
          return if node.block_literal?
          return unless (dot_node, receiver, argument, method_name = bad_intersection?(node))

          dot = dot_node.loc.dot.source
          bang = straight?(method_name) ? '' : '!'
          replacement = "#{bang}#{receiver.source}#{dot}intersect?(#{argument.source})"

          register_offense(node, replacement)
        end
        alias on_csend on_send

        def on_block(node)
          return unless (receiver, method_name, argument = any_none_block_intersection(node))

          dot = node.send_node.loc.dot.source
          bang = method_name == :any? ? '' : '!'
          replacement = "#{bang}#{receiver.source}#{dot}intersect?(#{argument.source})"

          register_offense(node, replacement)
        end
        alias on_numblock on_block
        alias on_itblock on_block

        private

        def bad_intersection?(node)
          bad_intersection_check?(node, bad_intersection_predicates) ||
            intersection_size_check?(node)
        end

        def bad_intersection_predicates
          if active_support_extensions_enabled?
            ACTIVE_SUPPORT_PREDICATES
          else
            PREDICATES
          end
        end

        def straight?(method_name)
          STRAIGHT_METHODS.include?(method_name.to_sym)
        end

        def register_offense(node, replacement)
          message = format(MSG, replacement: replacement, existing: node.source)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, replacement)
          end
        end
      end
    end
  end
end
