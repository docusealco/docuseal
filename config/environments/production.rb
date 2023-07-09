# frozen_string_literal: true

require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/string'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  config.public_file_server.headers = {
    'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000',
    'Expires' => 1.year.from_now.to_fs(:rfc822)
  }

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.active_record.sqlite3_production_warning = false

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = true

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service =
    if ENV['S3_ATTACHMENTS_BUCKET'].present?
      :aws_s3
    elsif ENV['GCS_BUCKET'].present?
      :google
    elsif ENV['AZURE_CONTAINER'].present?
      :azure
    else
      :disk
    end

  config.active_storage.resolve_model_to_route = :rails_storage_proxy if ENV['ACTIVE_STORAGE_PUBLIC'] != 'true'

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ENV['FORCE_SSL'] == 'true'

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  config.cache_store = :memory_store

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = false

  if ENV['SMTP_USERNAME']
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS', nil),
      port: ENV.fetch('SMTP_PORT', 587),
      domain: ENV.fetch('SMTP_DOMAIN', nil),
      user_name: ENV.fetch('SMTP_USERNAME', nil),
      password: ENV.fetch('SMTP_PASSWORD', nil),
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain'),
      enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true'
    }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  logger           = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger    = ActiveSupport::TaggedLogging.new(logger)

  encryption_secret = Digest::SHA256.hexdigest(ENV['SECRET_KEY_BASE'].to_s)

  config.active_record.encryption = {
    primary_key: encryption_secret.first(32),
    deterministic_key: encryption_secret.last(32),
    key_derivation_salt: Digest::SHA256.hexdigest(encryption_secret)
  }

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.base_controller_class = ['ActionController::API', 'ActionController::Base']

  config.lograge.custom_payload do |controller|
    {
      fwd: controller.request.ip
    }
  end
end
