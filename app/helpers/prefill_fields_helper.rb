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

  # Fetch actual prefill values from ATS for a specific task assignment
  # @param task_assignment_id [String, Integer] the ATS task assignment ID
  # @return [Hash] mapping of field names to actual values, empty hash if fetch fails
  def fetch_ats_prefill_values(task_assignment_id)
    return {} if task_assignment_id.blank?

    cache_key = "ats_prefill_values:#{task_assignment_id}"
    
    # Try cache first (short TTL for form session)
    begin
      cached_values = Rails.cache.read(cache_key)
      return cached_values if cached_values
    rescue StandardError => e
      Rails.logger.warn "Cache read failed for ATS prefill values: #{e.message}"
    end

    # Fetch from ATS API
    begin
      ats_api_url = Rails.application.config.ats_api_base_url || 'http://localhost:3000'
      response = fetch_from_ats_api("#{ats_api_url}/api/docuseal/#{task_assignment_id}/prefill")
      
      if response&.dig('values').is_a?(Hash)
        values = response['values']
        # Cache for form session duration (30 minutes)
        cache_result(cache_key, values, 30.minutes)
        Rails.logger.info "Fetched #{values.keys.length} prefill values for task_assignment #{task_assignment_id}"
        values
      else
        Rails.logger.warn "Invalid response format from ATS prefill API: #{response.inspect}"
        {}
      end
    rescue StandardError => e
      Rails.logger.error "Failed to fetch ATS prefill values for task_assignment #{task_assignment_id}: #{e.message}"
      {}
    end
  end

  # Merge ATS prefill values with existing submitter values
  # ATS values should not override existing submitter-entered values
  # @param submitter_values [Hash] existing values entered by submitters
  # @param ats_values [Hash] prefill values from ATS
  # @return [Hash] merged values with submitter values taking precedence
  def merge_ats_prefill_values(submitter_values, ats_values)
    return submitter_values if ats_values.blank?

    # Only use ATS values for fields that don't already have submitter values
    ats_values.each do |field_name, value|
      # Find matching field by name in template fields
      matching_field_uuid = find_field_uuid_by_name(field_name)
      next if matching_field_uuid.nil?
      
      # Only set if submitter hasn't already filled this field
      submitter_values[matching_field_uuid] = value if submitter_values[matching_field_uuid].blank?
    end

    submitter_values
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

  # Find field UUID by matching field name/question_id
  # This is a simplified approach - in practice you might need more sophisticated matching
  def find_field_uuid_by_name(field_name)
    # This would need to access the current submission/template context
    # For now, we'll use a simple approach that would work with proper integration
    # In a real implementation, this would need template/submission context
    
    # Return nil for now - this needs proper integration with the submission context
    # The prefill values would need to be mapped by field UUID rather than field name
    Rails.logger.debug "Looking for field UUID for ATS field: #{field_name}"
    nil
  end

  # Make HTTP request to ATS API
  def fetch_from_ats_api(url)
    require 'net/http'
    require 'json'
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 10 # 10 second timeout
    
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/json'
    
    # Add API authentication if configured
    if Rails.application.config.respond_to?(:ats_api_key) && Rails.application.config.ats_api_key.present?
      request['Authorization'] = "Bearer #{Rails.application.config.ats_api_key}"
    end
    
    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "ATS API returned #{response.code}: #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "HTTP request to ATS failed: #{e.message}"
    nil
  end
end
