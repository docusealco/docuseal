# frozen_string_literal: true

unless ENV['DOCKER_BUILD'] || ENV['CI_BUILD']
  Airbrake.configure do |config|
    config.project_key = ENV['AIRBRAKE_KEY'] # rubocop:disable Style/FetchEnvVar
    config.project_id = ENV['AIRBRAKE_ID'] # rubocop:disable Style/FetchEnvVar
    config.environment = Rails.env
    config.ignore_environments = %w[development test]
    config.root_directory = '/var/cpd/app'
  end
end
