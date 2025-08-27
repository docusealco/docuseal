# frozen_string_literal: true

module AtsPrefill
  module CacheManager
    # Cache TTL for ATS field parsing (1 hour)
    FIELD_EXTRACTION_TTL = 3600

    # Cache TTL for field UUID lookup optimization (30 minutes)
    FIELD_MAPPING_TTL = 1800

    # Maximum number of cached entries to prevent memory bloat
    MAX_CACHE_ENTRIES = 1000

    module_function

    # Fetches field extraction results from cache or computes them
    #
    # @param cache_key [String] The cache key to use
    # @yield Block that computes the value if not cached
    # @return [Array<String>] Array of valid field names
    def fetch_field_extraction(cache_key, &)
      fetch_with_fallback(cache_key, FIELD_EXTRACTION_TTL, &)
    end

    # Fetches field mapping results from cache or computes them
    #
    # @param cache_key [String] The cache key to use
    # @yield Block that computes the value if not cached
    # @return [Hash] Mapping of field names to UUIDs
    def fetch_field_mapping(cache_key, &)
      fetch_with_fallback(cache_key, FIELD_MAPPING_TTL, &)
    end

    # Generates a secure cache key using SHA256 hash
    #
    # @param prefix [String] Cache key prefix
    # @param data [String] Data to hash for the key
    # @return [String] Secure cache key
    def generate_cache_key(prefix, data)
      hash = Digest::SHA256.hexdigest(data.to_s)
      "#{prefix}:#{hash}"
    end

    # Writes a value to cache with error handling
    #
    # @param cache_key [String] The cache key
    # @param value [Object] The value to cache
    # @param ttl [Integer] Time to live in seconds
    # @return [void]
    def write_to_cache(cache_key, value, ttl)
      Rails.cache.write(cache_key, value, expires_in: ttl)
    rescue StandardError
      # Continue execution even if caching fails
    end

    # Reads from cache with error handling
    #
    # @param cache_key [String] The cache key to read
    # @return [Object, nil] Cached value or nil if not found/error
    def read_from_cache(cache_key)
      Rails.cache.read(cache_key)
    rescue StandardError
      # Return nil if cache read fails, allowing normal processing to continue
      nil
    end

    private

    # Fetches from cache or computes value with fallback on cache errors
    #
    # @param cache_key [String] The cache key
    # @param ttl [Integer] Time to live in seconds
    # @yield Block that computes the value if not cached
    # @return [Object] Cached or computed value
    def fetch_with_fallback(cache_key, ttl, &)
      Rails.cache.fetch(cache_key, expires_in: ttl, &)
    rescue StandardError
      # Fallback to computation if cache fails
      yield
    end

    module_function :fetch_field_extraction, :fetch_field_mapping, :generate_cache_key, :write_to_cache,
                    :read_from_cache, :fetch_with_fallback
  end
end
