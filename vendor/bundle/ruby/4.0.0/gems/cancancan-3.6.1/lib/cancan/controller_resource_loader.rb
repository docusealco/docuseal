# frozen_string_literal: true

require_relative 'controller_resource_finder.rb'
require_relative 'controller_resource_name_finder.rb'
require_relative 'controller_resource_builder.rb'
require_relative 'controller_resource_sanitizer.rb'
module CanCan
  module ControllerResourceLoader
    include CanCan::ControllerResourceNameFinder
    include CanCan::ControllerResourceFinder
    include CanCan::ControllerResourceBuilder
    include CanCan::ControllerResourceSanitizer

    def load_resource
      return if skip?(:load)

      if load_instance?
        self.resource_instance ||= load_resource_instance
      elsif load_collection?
        self.collection_instance ||= load_collection
      end
    end

    protected

    def new_actions
      %i[new create] + Array(@options[:new])
    end

    def resource_params_by_key(key)
      return unless @options[key] && @params.key?(extract_key(@options[key]))

      @params[extract_key(@options[key])]
    end

    def resource_params_by_namespaced_name
      resource_params_by_key(:instance_name) || resource_params_by_key(:class) || (
      params = @params[extract_key(namespaced_name)]
      params.respond_to?(:to_h) ? params : nil)
    end

    def resource_params
      if parameters_require_sanitizing? && params_method.present?
        sanitize_parameters
      else
        resource_params_by_namespaced_name
      end
    end

    def fetch_parent(name)
      if @controller.instance_variable_defined? "@#{name}"
        @controller.instance_variable_get("@#{name}")
      elsif @controller.respond_to?(name, true)
        @controller.send(name)
      end
    end

    # The object to load this resource through.
    def parent_resource
      parent_name && fetch_parent(parent_name)
    end

    def parent_name
      @options[:through] && [@options[:through]].flatten.detect { |i| fetch_parent(i) }
    end

    def resource_base_through_parent_resource
      if @options[:singleton]
        resource_class
      else
        parent_resource.send(@options[:through_association] || name.to_s.pluralize)
      end
    end

    def resource_base_through
      if parent_resource
        resource_base_through_parent_resource
      elsif @options[:shallow]
        resource_class
      else
        # maybe this should be a record not found error instead?
        raise AccessDenied.new(nil, authorization_action, resource_class)
      end
    end

    # The object that methods (such as "find", "new" or "build") are called on.
    # If the :through option is passed it will go through an association on that instance.
    # If the :shallow option is passed it will use the resource_class if there's no parent
    # If the :singleton option is passed it won't use the association because it needs to be handled later.
    def resource_base
      @options[:through] ? resource_base_through : resource_class
    end

    def parent_authorization_action
      @options[:parent_action] || :show
    end

    def authorization_action
      parent? ? parent_authorization_action : @params[:action].to_sym
    end

    def load_collection
      resource_base.accessible_by(current_ability, authorization_action)
    end

    def load_resource_instance
      if !parent? && new_actions.include?(@params[:action].to_sym)
        build_resource
      elsif id_param || @options[:singleton]
        find_resource
      end
    end

    private

    def extract_key(value)
      value.to_s.underscore.tr('/', '_')
    end
  end
end
