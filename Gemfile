# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

gem 'aws-sdk-s3', require: false
gem 'azure-storage-blob', require: false
gem 'bootsnap', require: false
gem 'devise'
gem 'dotenv', require: false
gem 'faraday'
gem 'google-cloud-storage', require: false
gem 'hexapdf'
gem 'image_processing'
gem 'lograge'
gem 'mysql2', require: false
gem 'oj'
gem 'omniauth-google-oauth2'
gem 'omniauth-rails_csrf_protection'
gem 'pagy'
gem 'pg', require: false
gem 'premailer-rails'
gem 'puma'
gem 'rails'
gem 'rails-i18n'
gem 'rollbar', require: ENV.key?('ROLLBAR_ACCESS_TOKEN')
gem 'ruby-vips'
gem 'shakapacker'
gem 'sidekiq', require: ENV.key?('REDIS_URL')
gem 'sqlite3', require: false
gem 'strip_attributes'
gem 'turbo-rails'
gem 'tzinfo-data'

group :development, :test do
  gem 'annotate'
  gem 'better_html'
  gem 'bullet'
  gem 'debug'
  gem 'erb_lint', require: false
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
end

group :development do
  gem 'letter_opener_web'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'cuprite'
  gem 'webmock'
end
