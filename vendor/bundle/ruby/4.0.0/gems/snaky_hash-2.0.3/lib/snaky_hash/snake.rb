# This is a module-class hybrid.
#
# A flexible key conversion system that supports both String and Symbol keys,
# with optional serialization capabilities.
#
# @example Basic usage with string keys
#   class MyHash < Hashie::Mash
#     include SnakyHash::Snake.new(key_type: :string)
#   end
#
# @example Usage with symbol keys and serialization
#   class MySerializableHash < Hashie::Mash
#     include SnakyHash::Snake.new(key_type: :symbol, serializer: true)
#   end
#
# Hashie's standard SymbolizeKeys is similar to the functionality we want.
# ... but not quite.  We need to support both String (for oauth2) and Symbol keys (for oauth).
# see: Hashie::Extensions::Mash::SymbolizeKeys
#
module SnakyHash
  # Creates a module that provides key conversion functionality when included
  #
  # @note Unlike Hashie::Mash, this implementation allows for both String and Symbol key types
  class Snake < Module
    # Initialize a new Snake module
    #
    # @param key_type [Symbol] the type to convert keys to (:string or :symbol)
    # @param serializer [Boolean] whether to include serialization capabilities
    # @raise [ArgumentError] if key_type is not :string or :symbol
    def initialize(key_type: :string, serializer: false)
      super()
      @key_type = key_type
      @serializer = serializer
    end

    # Includes appropriate conversion methods into the base class
    #
    # @param base [Class] the class including this module
    # @return [void]
    def included(base)
      conversions_module = SnakyModulizer.to_mod(@key_type)
      base.include(conversions_module)
      if @serializer
        base.extend(SnakyHash::Serializer)
      end
    end

    # Internal module factory for creating key conversion functionality
    module SnakyModulizer
      class << self
        # Creates a new module with key conversion methods based on the specified key type
        #
        # @param key_type [Symbol] the type to convert keys to (:string or :symbol)
        # @return [Module] a new module with conversion methods
        # @raise [ArgumentError] if key_type is not supported
        def to_mod(key_type)
          Module.new do
            case key_type
            when :string then
              # Converts a key to a string if it is symbolizable, after underscoring
              #
              # @note checks for to_sym instead of to_s, because nearly everything responds_to?(:to_s)
              #       so respond_to?(:to_s) isn't very useful as a test, and would result in symbolizing integers
              #       amd it also provides parity between the :symbol behavior, and the :string behavior,
              #       regarding which keys get converted for a given version of Ruby.
              #
              # @param key [Object] the key to convert
              # @return [String, Object] the converted key or original if not convertible
              define_method(:convert_key) { |key| key.respond_to?(:to_sym) ? underscore_string(key.to_s) : key }
            when :symbol then
              # Converts a key to a symbol if possible, after underscoring
              #
              # @param key [Object] the key to convert
              # @return [Symbol, Object] the converted key or original if not convertible
              define_method(:convert_key) { |key| key.respond_to?(:to_sym) ? underscore_string(key.to_s).to_sym : key }
            else
              raise ArgumentError, "SnakyHash: Unhandled key_type: #{key_type}"
            end

            # Converts hash values to the appropriate type when assigning
            #
            # @param val [Object] the value to convert
            # @param duping [Boolean] whether the value is being duplicated
            # @return [Object] the converted value
            define_method :convert_value do |val, duping = false| #:nodoc:
              case val
              when self.class
                val.dup
              when ::Hash
                val = val.dup if duping
                self.class.new(val)
              when ::Array
                val.collect { |e| convert_value(e) }
              else
                val
              end
            end

            # Converts a string to underscore case
            #
            # @param str [String, #to_s] the string to convert
            # @return [String] the underscored string
            # @example
            #   underscore_string("CamelCase")  #=> "camel_case"
            #   underscore_string("API::V1")    #=> "api/v1"
            # @note This is the same as ActiveSupport's String#underscore
            define_method :underscore_string do |str|
              str.to_s.strip.
                tr(" ", "_").
                gsub("::", "/").
                gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
                gsub(/([a-z\d])([A-Z])/, '\1_\2').
                tr("-", "_").
                squeeze("_").
                downcase
            end
          end
        end
      end
    end
  end
end
