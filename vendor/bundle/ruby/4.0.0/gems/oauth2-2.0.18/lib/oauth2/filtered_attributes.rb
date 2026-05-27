module OAuth2
  # Mixin that redacts sensitive instance variables in #inspect output.
  #
  # Classes include this module and declare which attributes should be filtered
  # using {.filtered_attributes}. Any instance variable name that includes one of
  # those attribute names will be shown as [FILTERED] in the object's inspect.
  module FilteredAttributes
    # Hook invoked when the module is included. Extends the including class with
    # class-level helpers.
    #
    # @param [Class] base The including class
    # @return [void]
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class-level helpers for configuring filtered attributes.
    module ClassMethods
      # Declare attributes that should be redacted in inspect output.
      #
      # @param [Array<Symbol, String>] attributes One or more attribute names
      # @return [void]
      def filtered_attributes(*attributes)
        @filtered_attribute_names = attributes.map(&:to_sym)
      end

      # The configured attribute names to filter.
      #
      # @return [Array<Symbol>]
      def filtered_attribute_names
        @filtered_attribute_names || []
      end
    end

    # Custom inspect that redacts configured attributes.
    #
    # @return [String]
    def inspect
      filtered_attribute_names = self.class.filtered_attribute_names
      return super if filtered_attribute_names.empty?

      inspected_vars = instance_variables.map do |var|
        if filtered_attribute_names.any? { |filtered_var| var.to_s.include?(filtered_var.to_s) }
          "#{var}=[FILTERED]"
        else
          "#{var}=#{instance_variable_get(var).inspect}"
        end
      end
      "#<#{self.class}:#{object_id} #{inspected_vars.join(", ")}>"
    end
  end
end
