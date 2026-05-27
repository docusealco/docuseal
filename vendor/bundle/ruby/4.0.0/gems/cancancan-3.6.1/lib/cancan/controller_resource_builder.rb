# frozen_string_literal: true

module CanCan
  module ControllerResourceBuilder
    protected

    def build_resource
      resource = resource_base.new(resource_params || {})
      assign_attributes(resource)
    end

    def assign_attributes(resource)
      resource.send("#{parent_name}=", parent_resource) if @options[:singleton] && parent_resource
      initial_attributes.each do |attr_name, value|
        resource.send("#{attr_name}=", value)
      end
      resource
    end

    def initial_attributes
      current_ability.attributes_for(@params[:action].to_sym, resource_class).delete_if do |key, _value|
        resource_params && resource_params.include?(key)
      end
    end
  end
end
