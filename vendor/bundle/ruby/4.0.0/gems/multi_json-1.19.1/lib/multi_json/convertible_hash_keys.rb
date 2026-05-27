module MultiJson
  # Mixin for converting hash keys between symbols and strings
  #
  # @api private
  module ConvertibleHashKeys
    SIMPLE_OBJECT_CLASSES = [String, Numeric, TrueClass, FalseClass, NilClass].freeze
    private_constant :SIMPLE_OBJECT_CLASSES

    private

    # Converts hash keys to symbols recursively
    #
    # @api private
    # @param value [Object] value to convert
    # @return [Object] value with symbolized keys
    def symbolize_keys(value)
      convert_hash_keys(value) { |key| key.respond_to?(:to_sym) ? key.to_sym : key }
    end

    # Converts hash keys to strings recursively
    #
    # @api private
    # @param value [Object] value to convert
    # @return [Object] value with stringified keys
    def stringify_keys(value)
      convert_hash_keys(value) { |key| key.respond_to?(:to_s) ? key.to_s : key }
    end

    # Recursively converts hash keys using the given block
    #
    # @api private
    # @param value [Object] value to convert
    # @yield [key] block to transform each key
    # @return [Object] converted value
    def convert_hash_keys(value, &key_modifier)
      case value
      when Hash
        value.to_h { |k, v| [key_modifier.call(k), convert_hash_keys(v, &key_modifier)] }
      when Array
        value.map { |v| convert_hash_keys(v, &key_modifier) }
      else
        convert_simple_object(value)
      end
    end

    # Converts non-hash objects to a JSON-safe format
    #
    # @api private
    # @param obj [Object] object to convert
    # @return [Object] converted object
    def convert_simple_object(obj)
      return obj if simple_object?(obj) || obj.respond_to?(:to_json)

      obj.respond_to?(:to_s) ? obj.to_s : obj
    end

    # Checks if an object is a simple JSON-safe type
    #
    # @api private
    # @param obj [Object] object to check
    # @return [Boolean] true if object is a simple type
    def simple_object?(obj)
      SIMPLE_OBJECT_CLASSES.any? { |klass| obj.is_a?(klass) }
    end
  end
end
