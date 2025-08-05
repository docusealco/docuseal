# frozen_string_literal: true

require 'faraday'

class ExportService
  attr_reader :error_message

  def initialize
    @error_message = nil
  end

  def record_error(message)
    @error_message = message
  end

  protected

  def api_connection
    @api_connection ||= Faraday.new(url: ExportLocation.default_location.api_base_url) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  rescue StandardError => e
    Rails.logger.error("Failed to create API connection: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    nil
  end

  def post_to_api(data, endpoint, extra_params = nil)
    connection = api_connection
    return nil unless connection

    connection.post(endpoint) do |req|
      data = data.merge(extra_params) if extra_params.present? && data.is_a?(Hash)
      req.body = data.is_a?(String) ? data : data.to_json
    end
  end

  def export_location
    @export_location ||= ExportLocation.default_location
  end
end
