# frozen_string_literal: true

require_relative 'hash_transform_method/autocorrection'

module RuboCop
  module Cop
    # Common functionality for Style/HashTransformKeys and
    # Style/HashTransformValues
    module HashTransformMethod
      extend NodePattern::Macros

      RESTRICT_ON_SEND = %i[[] to_h].freeze

      # Internal helper class to hold match data
      Captures = Struct.new(:transformed_argname, :transforming_body_expr, :unchanged_body_expr) do
        def noop_transformation?
          transforming_body_expr.lvar_type? &&
            transforming_body_expr.children == [transformed_argname]
        end

        def transformation_uses_both_args?
          transforming_body_expr.descendants.include?(unchanged_body_expr)
        end

        def use_transformed_argname?
          transforming_body_expr.each_descendant(:lvar).any? do |node|
            node.source == transformed_argname.to_s
          end
        end
      end

      # @!method hash_receiver?(node)
      def_node_matcher :hash_receiver?, <<~PATTERN
        {(hash ...)
         (send _ {:to_h :to_hash :merge :merge! :update :invert :except :tally} ...)
         (block (send _ {:group_by :to_h :tally :transform_keys :transform_keys!
                         :transform_values :transform_values!}) ...)
         (block (send _ :each_with_object (hash)) ...)}
      PATTERN

      def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler, InternalAffairs/ItblockHandler
        on_bad_each_with_object(node) do |*match|
          handle_possible_offense(node, match, 'each_with_object')
        end

        return if target_ruby_version < 2.6

        on_bad_to_h(node) { |*match| handle_possible_offense(node, match, 'to_h {...}') }
      end

      def on_send(node)
        on_bad_hash_brackets_map(node) do |*match|
          handle_possible_offense(node, match, 'Hash[_.map {...}]')
        end
        on_bad_map_to_h(node) { |*match| handle_possible_offense(node, match, 'map {...}.to_h') }
      end

      def on_csend(node)
        on_bad_map_to_h(node) { |*match| handle_possible_offense(node, match, 'map {...}.to_h') }
      end

      private

      # @abstract Implemented with `def_node_matcher`
      def on_bad_each_with_object(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_hash_brackets_map(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_map_to_h(_node)
        raise NotImplementedError
      end

      # @abstract Implemented with `def_node_matcher`
      def on_bad_to_h(_node)
        raise NotImplementedError
      end

      def handle_possible_offense(node, match, match_desc)
        captures = extract_captures(match)

        # If key didn't actually change either, this is most likely a false
        # positive (receiver isn't a hash).
        return if captures.noop_transformation?

        # Can't `transform_keys` if key transformation uses value, or
        # `transform_values` if value transformation uses key.
        return if captures.transformation_uses_both_args?

        return unless captures.use_transformed_argname?

        message = "Prefer `#{new_method_name}` over `#{match_desc}`."
        add_offense(node, message: message) do |corrector|
          correction = prepare_correction(node)
          execute_correction(corrector, node, correction)
        end
      end

      # @abstract
      #
      # @return [Captures]
      def extract_captures(_match)
        raise NotImplementedError
      end

      # @abstract
      #
      # @return [String]
      def new_method_name
        raise NotImplementedError
      end

      def prepare_correction(node)
        if (match = on_bad_each_with_object(node))
          Autocorrection.from_each_with_object(node, match)
        elsif (match = on_bad_hash_brackets_map(node))
          Autocorrection.from_hash_brackets_map(node, match)
        elsif (match = on_bad_map_to_h(node))
          Autocorrection.from_map_to_h(node, match)
        elsif (match = on_bad_to_h(node))
          Autocorrection.from_to_h(node, match)
        else
          raise 'unreachable'
        end
      end

      def execute_correction(corrector, node, correction)
        correction.strip_prefix_and_suffix(node, corrector)
        correction.set_new_method_name(new_method_name, corrector)

        captures = extract_captures(correction.match)
        correction.set_new_arg_name(captures.transformed_argname, corrector)
        correction.set_new_body_expression(captures.transforming_body_expr, corrector)
      end
    end
  end
end
