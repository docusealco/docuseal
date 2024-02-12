# frozen_string_literal: true

require 'rollbar' if ENV.key?('ROLLBAR_ACCESS_TOKEN')

if defined?(Rollbar)
  Rollbar.configure do |config|
    config.access_token = ENV.fetch('ROLLBAR_ACCESS_TOKEN', nil)

    config.transform << proc do |options|
      data = options[:payload]['data']

      if data[:request]
        data[:request][:cookies] = {}
        data[:request][:session] = {}
        data[:request][:url] = data[:request][:url].to_s.sub(%r{(/[sde]/)\w{8}}, '\1********')
      end
    end

    config.enabled = true
    config.collect_user_ip = false
    config.anonymize_user_ip = true
    config.scrub_headers += %w[X-Auth-Token Cookie X-Csrf-Token Referer]
    config.scrub_fields += %i[slug uuid attachment_uuid]

    config.exception_level_filters['ActionController::RoutingError'] = 'ignore'

    config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env
  end
end
