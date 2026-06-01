# frozen_string_literal: true

module Aws
  # @api private
  # A simple thread safe LRU cache
  class LRUCache
    # @param [Hash] options
    # @option options [Integer] :max_entries (100) Maximum number of entries
    # @option options [Integer] :expiration (nil) Expiration time in seconds
    def initialize(options = {})
      @max_entries = options[:max_entries] || 100
      @expiration = options[:expiration]
      @entries = {}
      @mutex = Mutex.new
    end

    # @param [String] key
    # @return [Object]
    def [](key)
      @mutex.synchronize do
        value = @entries[key]
        if value
          @entries.delete(key)
          @entries[key] = value unless value.expired?
        end
        @entries[key]&.value
      end
    end

    # @param [String] key
    # @param [Object] value
    def []=(key, value)
      @mutex.synchronize do
        @entries.shift unless @entries.size < @max_entries
        # delete old value if exists
        @entries.delete(key)
        @entries[key] = Entry.new(value: value, expiration: @expiration)
        @entries[key].value
      end
    end

    # @param [String] key
    # @return [Boolean]
    def key?(key)
      @mutex.synchronize do
        @entries.delete(key) if @entries.key?(key) && @entries[key].expired?
        @entries.key?(key)
      end
    end

    def clear
      @mutex.synchronize do
        @entries.clear
      end
    end

    # @api private
    class Entry
      def initialize(options = {})
        @value = options[:value]
        @expiration = options[:expiration]
        @created_time = Time.now
      end

      # @return [Object]
      attr_reader :value

      def expired?
        return false unless @expiration

        Time.now - @created_time > @expiration
      end
    end
  end
end
