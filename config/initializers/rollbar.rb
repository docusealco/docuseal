# frozen_string_literal: true

if defined?(Rollbar)
  Rollbar.configure do |config|
    config.access_token = ENV.fetch('ROLLBAR_ACCESS_TOKEN', nil)

    config.enabled = true

    config.exception_level_filters['ActionController::RoutingError'] = 'ignore'

    config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env
  end
end
