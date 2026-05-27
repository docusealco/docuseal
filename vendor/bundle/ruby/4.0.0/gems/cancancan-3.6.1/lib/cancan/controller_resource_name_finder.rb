# frozen_string_literal: true

module CanCan
  module ControllerResourceNameFinder
    protected

    def name_from_controller
      @params[:controller].split('/').last.singularize
    end

    def namespaced_name
      [namespace, name].join('/').singularize.camelize.safe_constantize || name
    end

    def name
      @name || name_from_controller
    end

    def namespace
      @params[:controller].split('/')[0..-2]
    end
  end
end
