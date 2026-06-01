# frozen_string_literal: true

module CanCan
  module ControllerResourceSanitizer
    protected

    def sanitize_parameters
      case params_method
      when Symbol
        @controller.send(params_method)
      when String
        @controller.instance_eval(params_method)
      when Proc
        params_method.call(@controller)
      end
    end

    def params_methods
      methods = ["#{@params[:action]}_params".to_sym, "#{name}_params".to_sym, :resource_params]
      methods.unshift(@options[:param_method]) if @options[:param_method].present?
      methods
    end

    def params_method
      params_methods.each do |method|
        return method if (method.is_a?(Symbol) && @controller.respond_to?(method, true)) ||
                         method.is_a?(String) || method.is_a?(Proc)
      end
      nil
    end
  end
end
