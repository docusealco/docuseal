module MultiJson
  # Thread-safe LRU-like cache for merged options hashes
  #
  # Caches are separated for load and dump operations. Each cache is
  # bounded to prevent unbounded memory growth when options are
  # generated dynamically.
  #
  # @api private
  module OptionsCache
    # Maximum entries before oldest entry is evicted
    MAX_CACHE_SIZE = 1000

    # Thread-safe cache store using double-checked locking pattern
    #
    # @api private
    class Store
      # Sentinel value to detect cache misses (unique object identity)
      NOT_FOUND = Object.new

      # Create a new cache store
      #
      # @api private
      # @return [Store] new store instance
      def initialize
        @cache = {}
        @mutex = Mutex.new
      end

      # Clear all cached entries
      #
      # @api private
      # @return [void]
      def reset
        @mutex.synchronize { @cache.clear }
      end

      # Fetch a value from cache or compute it
      #
      # @api private
      # @param key [Object] cache key
      # @param default [Object] default value if key not found
      # @yield block to compute value if not cached
      # @return [Object] cached or computed value
      def fetch(key, default = nil)
        # Fast path: check cache without lock (safe for reads)
        value = @cache.fetch(key, NOT_FOUND)
        return value unless value.equal?(NOT_FOUND)

        # Slow path: acquire lock and compute value
        @mutex.synchronize do
          @cache.fetch(key) { block_given? ? store(key, yield) : default }
        end
      end

      private

      # Stores a value in the cache with LRU eviction
      #
      # @api private
      # @param key [Object] cache key
      # @param value [Object] value to store
      # @return [Object] the stored value
      def store(key, value)
        # Double-check in case another thread computed while we waited
        @cache.fetch(key) do
          # Evict oldest entry if at capacity (Hash maintains insertion order)
          @cache.shift if @cache.size >= MAX_CACHE_SIZE
          @cache[key] = value
        end
      end
    end

    class << self
      # Get the dump options cache
      #
      # @api private
      # @return [Store] dump cache store
      attr_reader :dump

      # Get the load options cache
      #
      # @api private
      # @return [Store] load cache store
      attr_reader :load

      # Reset both caches
      #
      # @api private
      # @return [void]
      def reset
        @dump = Store.new
        @load = Store.new
      end
    end

    reset
  end
end
