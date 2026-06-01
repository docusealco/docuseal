require "singleton"
require_relative "options"

module MultiJson
  # Base class for JSON adapter implementations
  #
  # Each adapter wraps a specific JSON library (Oj, JSON gem, etc.) and
  # provides a consistent interface. Uses Singleton pattern so each adapter
  # class has exactly one instance.
  #
  # Subclasses must implement:
  # - #load(string, options) -> parsed object
  # - #dump(object, options) -> JSON string
  #
  # @api private
  class Adapter
    extend Options
    include Singleton

    class << self
      BLANK_PATTERN = /\A\s*\z/
      private_constant :BLANK_PATTERN

      # Hook called when a subclass is created
      #
      # @api private
      # @param subclass [Class] the new subclass
      # @return [void]
      def inherited(subclass)
        super
        # Propagate default options to subclasses
        subclass.instance_variable_set(:@default_load_options, @default_load_options) if defined?(@default_load_options)
        subclass.instance_variable_set(:@default_dump_options, @default_dump_options) if defined?(@default_dump_options)
      end

      # DSL for setting adapter-specific default options
      #
      # @api private
      # @param action [Symbol] :load or :dump
      # @param value [Hash] default options for the action
      # @return [Hash] the frozen options hash
      def defaults(action, value)
        instance_variable_set(:"@default_#{action}_options", value.freeze)
      end

      # Parse a JSON string into a Ruby object
      #
      # @api private
      # @param string [String, #read] JSON string or IO-like object
      # @param options [Hash] parsing options
      # @return [Object, nil] parsed object or nil for blank input
      def load(string, options = {})
        string = string.read if string.respond_to?(:read)
        return nil if blank?(string)

        instance.load(string, merged_load_options(options))
      end

      # Serialize a Ruby object to JSON
      #
      # @api private
      # @param object [Object] object to serialize
      # @param options [Hash] serialization options
      # @return [String] JSON string
      def dump(object, options = {})
        instance.dump(object, merged_dump_options(options))
      end

      private

      # Checks if the input is blank (nil or whitespace-only)
      #
      # @api private
      # @param input [String, nil] input to check
      # @return [Boolean] true if input is blank
      def blank?(input)
        input.nil? || BLANK_PATTERN.match?(input)
      rescue ArgumentError
        # Invalid byte sequence in UTF-8 - treat as non-blank
        false
      end

      # Merges dump options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_dump_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.dump.fetch(cache_key) do
          dump_options(cache_key).merge(MultiJson.dump_options(cache_key)).merge!(cache_key)
        end
      end

      # Merges load options from adapter, global, and call-site
      #
      # @api private
      # @param options [Hash] call-site options
      # @return [Hash] merged options hash
      def merged_load_options(options)
        cache_key = strip_adapter_key(options)
        OptionsCache.load.fetch(cache_key) do
          load_options(cache_key).merge(MultiJson.load_options(cache_key)).merge!(cache_key)
        end
      end

      # Removes the :adapter key from options for cache key
      #
      # @api private
      # @param options [Hash] original options
      # @return [Hash] frozen options without :adapter key
      def strip_adapter_key(options)
        options.except(:adapter).freeze
      end
    end
  end
end
