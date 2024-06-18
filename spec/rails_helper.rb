# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
ENV['TZ'] ||= 'UTC'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'capybara/cuprite'
require 'capybara/rspec'
require 'webmock/rspec'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

WebMock.disable_net_connect!(allow_localhost: true)

require 'simplecov' if ENV['COVERAGE']

Capybara.server = :puma, { Silent: true }
Capybara.disable_animation = true

Capybara.register_driver(:headless_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800],
                                     process_timeout: 20,
                                     timeout: 20,
                                     js_errors: true)
end

Capybara.register_driver(:headful_cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800],
                                     headless: false,
                                     process_timeout: 20,
                                     timeout: 20,
                                     js_errors: true)
end

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers
  config.include ActiveJob::TestHelper

  config.before(:each, type: :system) do
    if ENV['HEADLESS'] == 'false'
      driven_by :headful_cuprite
    else
      driven_by :headless_cuprite
    end
  end

  config.before do
    Sidekiq::Worker.clear_all
  end

  config.before do |example|
    Sidekiq::Testing.inline! if example.metadata[:sidekiq] == :inline
  end
end
