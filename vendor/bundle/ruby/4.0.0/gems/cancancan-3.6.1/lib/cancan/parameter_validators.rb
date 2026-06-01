# frozen_string_literal: true

module CanCan
  module ParameterValidators
    def valid_attribute_param?(attribute)
      attribute.nil? || attribute.is_a?(Symbol) || (attribute.is_a?(Array) && attribute.all? { |a| a.is_a?(Symbol) })
    end
  end
end
