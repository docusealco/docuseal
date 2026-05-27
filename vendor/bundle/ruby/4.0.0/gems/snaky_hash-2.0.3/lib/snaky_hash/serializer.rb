# frozen_string_literal: true

require "json"

module SnakyHash
  # Provides JSON serialization and deserialization capabilities with extensible value transformation
  #
  # @example Basic usage
  #   class MyHash < Hashie::Mash
  #     extend SnakyHash::Serializer
  #   end
  #   hash = MyHash.load('{"key": "value"}')
  #   hash.dump #=> '{"key":"value"}'
  #
  module Serializer
    class << self
      # Extends the base class with serialization capabilities
      #
      # @param base [Class] the class being extended
      # @return [void]
      def extended(base)
        extended_module = Modulizer.to_extended_mod
        base.extend(extended_module)
        base.include(ConvenienceInstanceMethods)
        # :nocov:
        # This will be run in CI on Ruby 2.3, but we only collect coverage from current Ruby
        unless base.instance_methods.include?(:transform_values)
          base.include(BackportedInstanceMethods)
        end
        # :nocov:
      end
    end

    # Serializes a hash object to JSON
    #
    # @param obj [Hash] the hash to serialize
    # @return [String] JSON string representation of the hash
    def dump(obj)
      hash = dump_hash(obj)
      hash.to_json
    end

    # Deserializes a JSON string into a hash object
    #
    # @param raw_hash [String, nil] JSON string to deserialize
    # @return [Hash] deserialized hash object
    def load(raw_hash)
      hash = JSON.parse(presence(raw_hash) || "{}")
      load_hash(new(hash))
    end

    # Internal module for generating extension methods
    module Modulizer
      class << self
        # Creates a new module with extension management methods
        #
        # @return [Module] a module containing extension management methods
        def to_extended_mod
          Module.new do
            define_method :load_value_extensions do
              @load_value_extensions ||= Extensions.new
            end

            define_method :load_extensions do
              load_value_extensions
            end

            define_method :dump_value_extensions do
              @dump_value_extensions ||= Extensions.new
            end

            define_method :dump_extensions do
              dump_value_extensions
            end

            define_method :load_hash_extensions do
              @load_hash_extensions ||= Extensions.new
            end

            define_method :dump_hash_extensions do
              @dump_hash_extensions ||= Extensions.new
            end
          end
        end
      end
    end

    # Provides backported methods for older Ruby versions
    module BackportedInstanceMethods
      # :nocov:
      # Transforms values of a hash using the given block
      #
      # @yield [Object] block to transform each value
      # @return [Hash] new hash with transformed values
      # @return [Enumerator] if no block given
      # @note This will be run in CI on Ruby 2.3, but we only collect coverage from current Ruby
      #       Rails <= 5.2 had a transform_values method, which was added to Ruby in version 2.4.
      #       This method is a backport of that original Rails method for Ruby 2.2 and 2.3.
      def transform_values(&block)
        return enum_for(:transform_values) { size } unless block_given?
        return {} if empty?
        result = self.class.new
        each do |key, value|
          result[key] = yield(value)
        end
        result
      end
      # :nocov:
    end

    # Provides convenient instance methods for serialization
    #
    # @example Using convenience methods
    #   hash = MyHash.new(key: 'value')
    #   json = hash.dump #=> '{"key":"value"}'
    module ConvenienceInstanceMethods
      # Serializes the current hash instance to JSON
      #
      # @return [String] JSON string representation of the hash
      def dump
        self.class.dump(self)
      end
    end

  private

    # Checks if a value is blank (nil or empty string)
    #
    # @param value [Object] value to check
    # @return [Boolean] true if value is blank
    def blank?(value)
      return true if value.nil?
      return true if value.is_a?(String) && value.empty?

      false
    end

    # Returns nil if value is blank, otherwise returns the value
    #
    # @param value [Object] value to check
    # @return [Object, nil] the value or nil if blank
    def presence(value)
      blank?(value) ? nil : value
    end

    # Processes a hash for dumping, transforming its keys and/or values
    #
    # @param hash [Hash] hash to process
    # @return [Hash] processed hash with transformed values
    def dump_hash(hash)
      dump_hash_extensions.run(self[hash]).transform_values do |value|
        dump_value(value)
      end
    end

    # Processes a single value for dumping
    #
    # @param value [Object] value to process
    # @return [Object, nil] processed value
    def dump_value(value)
      if blank?(value)
        return value
      end

      if value.is_a?(::Hash)
        return dump_hash(value)
      end

      if value.is_a?(::Array)
        return value.map { |v| dump_value(v) }.compact
      end

      dump_extensions.run(value)
    end

    # Processes a hash for loading, transforming its keys and/or values
    #
    # @param hash [Hash] hash to process
    # @return [Hash] processed hash with transformed values
    def load_hash(hash)
      ran = load_hash_extensions.run(self[hash])
      return load_value(ran) unless ran.is_a?(::Hash)

      res = self[ran].transform_values do |value|
        load_value(value)
      end

      # TODO: Drop this hack when dropping support for Ruby 2.6
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.7")
        res
      else
        # :nocov:
        # In Ruby <= 2.6 Hash#transform_values returned a new vanilla Hash,
        #   rather than a hash of the class being transformed.
        self[res]
        # :nocov:
      end
    end

    # Processes a single value for loading
    #
    # @param value [Object] value to process
    # @return [Object, nil] processed value
    def load_value(value)
      if blank?(value)
        return value
      end

      if value.is_a?(::Hash)
        return load_hash(value)
      end

      if value.is_a?(::Array)
        return value.map { |v| load_value(v) }.compact
      end

      load_extensions.run(value)
    end
  end
end
