# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for use of the helper methods which reference
      # instance variables.
      #
      # Relying on instance variables makes it difficult to reuse helper
      # methods.
      #
      # If it seems awkward to explicitly pass in each dependent
      # variable, consider moving the behavior elsewhere, for
      # example to a model, decorator or presenter.
      #
      # Provided that an instance variable belongs to a class,
      # an offense will not be registered.
      #
      # @example
      #   # bad
      #   def welcome_message
      #     "Hello #{@user.name}"
      #   end
      #
      #   # good
      #   def welcome_message(user)
      #     "Hello #{user.name}"
      #   end
      #
      #   # good
      #   module ButtonHelper
      #     class Welcome
      #       def initialize(text:)
      #         @text = text
      #       end
      #     end
      #
      #     def welcome(**)
      #       render Welcome.new(**)
      #     end
      #   end
      #
      class HelperInstanceVariable < Base
        MSG = 'Do not use instance variables in helpers.'

        def on_ivar(node)
          return if instance_variable_belongs_to_class?(node)

          add_offense(node)
        end

        def on_ivasgn(node)
          return if node.parent.or_asgn_type? || instance_variable_belongs_to_class?(node)

          add_offense(node.loc.name)
        end

        private

        def instance_variable_belongs_to_class?(node)
          node.each_ancestor(:class).any?
        end
      end
    end
  end
end
