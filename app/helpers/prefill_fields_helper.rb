# frozen_string_literal: true

module PrefillFieldsHelper
  # Cache TTL for ATS field parsing (1 hour)
  ATS_FIELDS_CACHE_TTL = 1.hour

  # Maximum number of cached entries to prevent memory bloat
  MAX_CACHE_ENTRIES = 1000

  def extract_ats_prefill_fields
    return [] if params[:ats_fields].blank?

    # Create cache key from parameter hash for security and uniqueness
    cache_key = ats_fields_cache_key(params[:ats_fields])

    # Try to get from cache first with error handling
    begin
      cached_result = Rails.cache.read(cache_key)
      if cached_result
        Rails.logger.debug { "ATS fields cache hit for key: #{cache_key}" }
        return cached_result
      end
    rescue StandardError => e
      Rails.logger.warn "Cache read failed for ATS fields: #{e.message}"
      # Continue with normal processing if cache read fails
    end

    # Cache miss - perform expensive operations
    Rails.logger.debug { "ATS fields cache miss for key: #{cache_key}" }

    begin
      decoded_json = Base64.urlsafe_decode64(params[:ats_fields])
      field_names = JSON.parse(decoded_json)

      # Validate that we got an array of strings
      return cache_and_return_empty(cache_key) unless field_names.is_a?(Array) && field_names.all?(String)

      # Filter to only expected field name patterns
      valid_fields = field_names.select { |name| valid_ats_field_name?(name) }

      # Cache the result with TTL (with error handling)
      cache_result(cache_key, valid_fields, ATS_FIELDS_CACHE_TTL)

      # Log successful field reception
      Rails.logger.info "Processed and cached #{valid_fields.length} ATS prefill fields: #{valid_fields.join(', ')}"

      valid_fields
    rescue StandardError => e
      Rails.logger.warn "Failed to parse ATS prefill fields: #{e.message}"
      # Cache empty result for failed parsing to avoid repeated failures
      cache_result(cache_key, [], 5.minutes)
      []
    end
  end

  # Clear ATS fields cache (useful for testing or manual cache invalidation)
  def clear_ats_fields_cache
    # Since we can't easily enumerate cache keys, we'll rely on TTL for cleanup
    # This method is provided for potential future use or testing
    Rails.logger.info 'ATS fields cache clear requested (relies on TTL for cleanup)'
  end

  private

  def valid_ats_field_name?(name)
    # Only allow expected field name patterns (security)
    name.match?(/\A(employee|manager|account|location)_[a-z_]+\z/)
  end

  def ats_fields_cache_key(ats_fields_param)
    # Create secure cache key using SHA256 hash of the parameter
    # This prevents cache key collisions and keeps keys reasonably sized
    hash = Digest::SHA256.hexdigest(ats_fields_param)
    "ats_fields:#{hash}"
  end

  def cache_result(cache_key, value, ttl)
    Rails.cache.write(cache_key, value, expires_in: ttl)
  rescue StandardError => e
    Rails.logger.warn "Cache write failed for ATS fields: #{e.message}"
    # Continue execution even if caching fails
  end

  def cache_and_return_empty(cache_key)
    cache_result(cache_key, [], 5.minutes)
    []
  end
end
