# frozen_string_literal: true

Rollbar.configure do |config|
  config.access_token = ENV.fetch('ROLLBAR_ACCESS_TOKEN', nil)

  config.enabled = !config.access_token.nil?

  config.exception_level_filters['ActionController::RoutingError'] = 'ignore'

  config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env
end
