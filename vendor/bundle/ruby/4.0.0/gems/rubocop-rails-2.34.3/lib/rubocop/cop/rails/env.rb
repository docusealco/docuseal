# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for usage of `Rails.env` which can be replaced with Feature Flags
      #
      # @example
      #
      #   # bad
      #   Rails.env.production? || Rails.env.local?
      #
      #   # good
      #   if FeatureFlag.enabled?(:new_feature)
      #     # new feature code
      #   end
      #
      class Env < Base
        MSG = 'Use Feature Flags or config instead of `Rails.env`.'
        RESTRICT_ON_SEND = %i[env].freeze
        # This allow list is derived from:
        # (Rails.env.methods - Object.instance_methods).select { |m| m.to_s.end_with?('?') }
        # and then removing the environment specific methods like development?, test?, production?, local?
        ALLOWED_LIST = Set.new(
          %i[
            unicode_normalized?
            exclude?
            empty?
            acts_like_string?
            include?
            is_utf8?
            casecmp?
            match?
            starts_with?
            ends_with?
            start_with?
            end_with?
            valid_encoding?
            ascii_only?
            between?
          ]
        ).freeze

        def on_send(node)
          return unless node.receiver&.const_name == 'Rails'

          parent = node.parent
          return unless parent.respond_to?(:predicate_method?) && parent.predicate_method?

          return if ALLOWED_LIST.include?(parent.method_name)

          add_offense(parent)
        end
      end
    end
  end
end
