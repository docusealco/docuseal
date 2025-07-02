# frozen_string_literal: true
require 'faraday'

class ExportController < ApplicationController
  skip_authorization_check
  skip_before_action :maybe_redirect_to_setup
  skip_before_action :verify_authenticity_token

  # Template is sent as JSON already; we're just gonnna send it on to the third party.
  # It's assumed that any extra details required will also be passed through from the front end - 
  # set by the ExportLocation.extra_params
  def export_template
    export_location = ExportLocation.default_location
    conn = Faraday.new(url: export_location.api_base_url) do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
    
    response = conn.post(export_location.templates_endpoint) do |req|
      # req.headers['Authorization'] = "Bearer #{export_location.authorization_token}" lol
      req.body = request.raw_post.present? ? JSON.parse(request.raw_post) : params.to_unsafe_h
      req.body.merge!(export_location.extra_params) if export_location.extra_params
    end
    
    if response.success?
      head :ok # alert: I18n.t('exports.templates.success')
    else
      Rails.logger.error("Failed to send to third party Faraday: #{response.status}")
      Rollbar.error("#{export_location.name} API error: #{response.status}") if defined?(Rollbar)
      head :ok # templates_path, alert: I18n.t('exports.templates.api_error')
    end
  rescue Faraday::Error => e
    Rails.logger.error("Failed to send to third party Faraday: #{e.message}")
    Rollbar.error("Failed to send to third party: #{e.message}") if defined?(Rollbar)
    redirect_to templates_path, alert: I18n.t('exports.templates.api_error')
  rescue StandardError => e
    Rails.logger.error("Failed to send to third party: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    redirect_to templates_path, alert: I18n.t('exports.templates.error')
  end
end
