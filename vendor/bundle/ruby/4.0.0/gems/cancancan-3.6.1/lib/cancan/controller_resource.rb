# frozen_string_literal: true

require_relative 'controller_resource_loader.rb'
module CanCan
  # Handle the load and authorization controller logic
  # so we don't clutter up all controllers with non-interface methods.
  # This class is used internally, so you do not need to call methods directly on it.
  class ControllerResource # :nodoc:
    include ControllerResourceLoader

    def self.add_before_action(controller_class, method, *args)
      options = args.extract_options!
      resource_name = args.first
      before_action_method = before_callback_name(options)
      controller_class.send(before_action_method, options.slice(:only, :except, :if, :unless)) do |controller|
        controller.class.cancan_resource_class
                  .new(controller, resource_name, options.except(:only, :except, :if, :unless)).send(method)
      end
    end

    def self.before_callback_name(options)
      options.delete(:prepend) ? :prepend_before_action : :before_action
    end

    def initialize(controller, *args)
      @controller = controller
      @params = controller.params
      @options = args.extract_options!
      @name = args.first
    end

    def load_and_authorize_resource
      load_resource
      authorize_resource
    end

    def authorize_resource
      return if skip?(:authorize)

      @controller.authorize!(authorization_action, resource_instance || resource_class_with_parent)
    end

    def parent?
      @options.key?(:parent) ? @options[:parent] : @name && @name != name_from_controller.to_sym
    end

    def skip?(behavior)
      return false unless (options = @controller.class.cancan_skipper[behavior][@name])

      options == {} ||
        options[:except] && !action_exists_in?(options[:except]) ||
        action_exists_in?(options[:only])
    end

    protected

    # Returns the class used for this resource. This can be overridden by the :class option.
    # If +false+ is passed in it will use the resource name as a symbol in which case it should
    # only be used for authorization, not loading since there's no class to load through.
    def resource_class
      case @options[:class]
      when false
        name.to_sym
      when nil
        namespaced_name.to_s.camelize.constantize
      when String
        @options[:class].constantize
      else
        @options[:class]
      end
    end

    def load_instance?
      parent? || member_action?
    end

    def load_collection?
      resource_base.respond_to?(:accessible_by) && !current_ability.has_block?(authorization_action, resource_class)
    end

    def member_action?
      new_actions.include?(@params[:action].to_sym) || @options[:singleton] ||
        ((@params[:id] || @params[@options[:id_param]]) &&
          !collection_actions.include?(@params[:action].to_sym))
    end

    def resource_class_with_parent
      parent_resource ? { parent_resource => resource_class } : resource_class
    end

    def resource_instance=(instance)
      @controller.instance_variable_set("@#{instance_name}", instance)
    end

    def resource_instance
      return unless load_instance? && @controller.instance_variable_defined?("@#{instance_name}")

      @controller.instance_variable_get("@#{instance_name}")
    end

    def collection_instance=(instance)
      @controller.instance_variable_set("@#{instance_name.to_s.pluralize}", instance)
    end

    def collection_instance
      return unless @controller.instance_variable_defined?("@#{instance_name.to_s.pluralize}")

      @controller.instance_variable_get("@#{instance_name.to_s.pluralize}")
    end

    def parameters_require_sanitizing?
      save_actions.include?(@params[:action].to_sym) || resource_params_by_namespaced_name.present?
    end

    def instance_name
      @options[:instance_name] || name
    end

    def collection_actions
      [:index] + Array(@options[:collection])
    end

    def save_actions
      %i[create update]
    end

    private

    def action_exists_in?(options)
      Array(options).include?(@params[:action].to_sym)
    end

    def adapter
      ModelAdapters::AbstractAdapter.adapter_class(resource_class)
    end

    def current_ability
      @controller.send(:current_ability)
    end
  end
end
