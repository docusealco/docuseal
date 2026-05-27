# frozen_string_literal: true

module SnakyHash
  # Manages extensions that can modify values in a chain of transformations
  #
  # @example Adding and running an extension
  #   extensions = Extensions.new
  #   extensions.add(:upcase) { |value| value.to_s.upcase }
  #   extensions.run("hello") #=> "HELLO"
  #
  class Extensions
    # Initializes a new Extensions instance with an empty extensions registry
    def initialize
      reset
    end

    # Reset the registry of extensions to an empty state
    #
    # @return [Hash] an empty hash of extensions
    def reset
      @extensions = {}
    end

    # Adds a new extension with the given name
    #
    # @param name [String, Symbol] the name of the extension
    # @yield [value] block that will be called with a value to transform
    # @raise [SnakyHash::Error] if an extension with the given name already exists
    # @return [Proc] the added extension block
    def add(name, &block)
      if has?(name)
        raise Error, "Extension already defined named '#{name}'"
      end

      @extensions[name.to_sym] = block
    end

    # Checks if an extension with the given name exists
    #
    # @param name [String, Symbol] the name of the extension to check
    # @return [Boolean] true if the extension exists, false otherwise
    def has?(name)
      @extensions.key?(name.to_sym)
    end

    # Runs all registered extensions in sequence on the given value
    #
    # @param value [Object] the value to transform through all extensions
    # @return [Object] the final transformed value after running all extensions
    def run(value)
      @extensions.each_value do |block|
        value = block.call(value)
      end
      value
    end
  end
end
