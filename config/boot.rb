# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

if ENV['RAILS_ENV'] == 'production' && ENV['SECRET_KEY_BASE'].to_s.empty?
  require 'dotenv'
  require 'securerandom'

  dotenv_path = "#{ENV.fetch('WORKDIR', '.')}/docuseal.env"

  unless File.exist?(dotenv_path)
    default_env = <<~TEXT
      DATABASE_URL= # keep empty to use sqlite or specify postgresql database URL
      SECRET_KEY_BASE=#{SecureRandom.hex(64)}
    TEXT

    File.write(dotenv_path, default_env)
  end

  database_url = ENV.fetch('DATABASE_URL', nil)

  Dotenv.load(dotenv_path)

  ENV['DATABASE_URL'] = ENV['DATABASE_URL'].to_s.empty? ? database_url : ENV.fetch('DATABASE_URL', nil)
end

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
