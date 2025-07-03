# frozen_string_literal: true

require 'faraday'

class ExportController < ApplicationController
  skip_authorization_check
  skip_before_action :maybe_redirect_to_setup
  skip_before_action :verify_authenticity_token

  # Template is sent as JSON already; we're just gonnna send it on to the third party.
  def export_template
    export_location = ExportLocation.default_location

    data = request.raw_post.present? ? JSON.parse(request.raw_post) : params.to_unsafe_h
    response = post_to_api(data, export_location.templates_endpoint, export_location.extra_params)

    if response&.success?
      Rails.logger.info("Successfully exported template #{data[:template][:name]} to #{export_location.name}")
      head :ok
    else
      Rails.logger.error("Failed to export template to third party: #{response&.status}")
      Rollbar.error("#{export_location.name} template export API error: #{response&.status}") if defined?(Rollbar)
      head :unprocessable_entity
    end
  rescue Faraday::Error => e
    Rails.logger.error("Failed to export template Faraday: #{e.message}")
    Rollbar.error("Failed to export template: #{e.message}") if defined?(Rollbar)
    head :service_unavailable
  rescue StandardError => e
    Rails.logger.error("Failed to export template: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    head :internal_server_error
  end

  private

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
      # req.headers['Authorization'] = "Bearer #{export_location.authorization_token}" lol

      # Merge extra_params into data if provided
      data = data.merge(extra_params) if extra_params.present? && data.is_a?(Hash)

      req.body = data.is_a?(String) ? data : data.to_json
    end
  end
end
