# frozen_string_literal: true
require 'faraday'

class ExportController < ApplicationController
  skip_before_action :maybe_redirect_to_setup
  skip_before_action :verify_authenticity_token

  # Template is sent as JSON already; we're just gonnna send it on to the third party
  def export_template
    conn = Faraday.new(url: 'https://api.thirdparty.com') do |faraday|
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
    
    response = conn.post('/endpoint') do |req|
      req.headers['Authorization'] = 'Bearer YOUR_API_KEY'
      # Pass along the entire JSON payload received in the request
      req.body = request.raw_post.present? ? JSON.parse(request.raw_post) : params.to_unsafe_h
    end
    
    if response.success?
      redirect_to templates_path, alert: I18n.t('exports.templates.success')
    else
      Rollbar.error("Third party API error: #{response.status} - #{response.body}") if defined?(Rollbar)
      redirect_to templates_path, alert: I18n.t('exports.templates.api_error')
    end
  rescue Faraday::Error => e
    Rollbar.error("Failed to send to third party: #{e.message}") if defined?(Rollbar)
    redirect_to templates_path, alert: I18n.t('exports.templates.api_error')
  rescue StandardError => e
    Rollbar.error(e) if defined?(Rollbar)
    redirect_to templates_path, alert: I18n.t('exports.templates.error')
  end
end
