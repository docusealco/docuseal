# frozen_string_literal: true

module CanCan
  module Ability
    module Actions
      # Alias one or more actions into another one.
      #
      #   alias_action :update, :destroy, :to => :modify
      #   can :modify, Comment
      #
      # Then :modify permission will apply to both :update and :destroy requests.
      #
      #   can? :update, Comment # => true
      #   can? :destroy, Comment # => true
      #
      # This only works in one direction. Passing the aliased action into the "can?" call
      # will not work because aliases are meant to generate more generic actions.
      #
      #   alias_action :update, :destroy, :to => :modify
      #   can :update, Comment
      #   can? :modify, Comment # => false
      #
      # Unless that exact alias is used.
      #
      #   can :modify, Comment
      #   can? :modify, Comment # => true
      #
      # The following aliases are added by default for conveniently mapping common controller actions.
      #
      #   alias_action :index, :show, :to => :read
      #   alias_action :new, :to => :create
      #   alias_action :edit, :to => :update
      #
      # This way one can use params[:action] in the controller to determine the permission.
      def alias_action(*args)
        target = args.pop[:to]
        validate_target(target)
        aliased_actions[target] ||= []
        aliased_actions[target] += args
      end

      # Returns a hash of aliased actions. The key is the target and the value is an array of actions aliasing the key.
      def aliased_actions
        @aliased_actions ||= default_alias_actions
      end

      # Removes previously aliased actions including the defaults.
      def clear_aliased_actions
        @aliased_actions = {}
      end

      private

      def default_alias_actions
        {
          read: %i[index show],
          create: [:new],
          update: [:edit]
        }
      end

      # Given an action, it will try to find all of the actions which are aliased to it.
      # This does the opposite kind of lookup as expand_actions.
      def aliases_for_action(action)
        results = [action]
        aliased_actions.each do |aliased_action, actions|
          results += aliases_for_action(aliased_action) if actions.include? action
        end
        results
      end

      def expanded_actions
        @expanded_actions ||= {}
      end

      # Accepts an array of actions and returns an array of actions which match.
      # This should be called before "matches?" and other checking methods since they
      # rely on the actions to be expanded.
      def expand_actions(actions)
        expanded_actions[actions] ||= begin
          expanded = []
          actions.each do |action|
            expanded << action
            if (aliases = aliased_actions[action])
              expanded += expand_actions(aliases)
            end
          end
          expanded
        end
      end
    end
  end
end
