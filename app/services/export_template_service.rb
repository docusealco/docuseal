# frozen_string_literal: true

class ExportTemplateService < ExportService
  def initialize(data)
    super()
    @data = data
  end

  def call
    response = post_to_api(@data, export_location.templates_endpoint, export_location.extra_params)

    if response&.success?
      Rails.logger.info("Successfully exported template #{@data[:template][:name]} to #{export_location.name}")
      true
    else
      Rails.logger.error("Failed to export template to third party: #{response&.status}")
      Rollbar.error("#{export_location.name} template export API error: #{response&.status}") if defined?(Rollbar)
      record_error('Failed to export template to third party')
      false
    end
  rescue Faraday::Error => e
    Rails.logger.error("Failed to export template Faraday: #{e.message}")
    Rollbar.error("Failed to export template: #{e.message}") if defined?(Rollbar)
    record_error("Network error occurred during template export: #{e.message}")
    false
  rescue StandardError => e
    Rails.logger.error("Failed to export template: #{e.message}")
    Rollbar.error(e) if defined?(Rollbar)
    record_error("An unexpected error occurred during template export: #{e.message}")
    false
  end
end
