# frozen_string_literal: true

# External configuration loaded from environment variables.
# Exposes SMTP and storage settings; additional external config concerns can be
# added here as needed.
module ExternalConfig
  CONFIG_DIR = ENV.fetch('DOCUSEAL_CONFIG_DIR', '/etc/docuseal')

  SMTP_ENV_KEYS = {
    address: 'DOCUSEAL_CONFIG_SMTP_ADDRESS',
    port: 'DOCUSEAL_CONFIG_SMTP_PORT',
    user_name: 'DOCUSEAL_CONFIG_SMTP_USERNAME',
    password: 'DOCUSEAL_CONFIG_SMTP_PASSWORD',
    domain: 'DOCUSEAL_CONFIG_SMTP_DOMAIN',
    from: 'DOCUSEAL_CONFIG_SMTP_FROM'
  }.freeze

  STORAGE_ENV_KEYS = {
    bucket: 'S3_ATTACHMENTS_BUCKET',
    access_key_id: 'AWS_ACCESS_KEY_ID',
    secret_access_key: 'AWS_SECRET_ACCESS_KEY',
    region: 'AWS_REGION',
    endpoint: 'S3_ENDPOINT'
  }.freeze

  module_function

  # SMTP is considered configured as soon as an address is provided via ENV.
  def smtp_configured?
    ENV.fetch(SMTP_ENV_KEYS[:address], nil).present?
  end

  # Returns an ActionMailer-compatible SMTP settings hash built from ENV vars.
  # The :from key is returned alongside but is intended for message[:from]
  # rewriting, not for Net::SMTP.
  def smtp_settings
    return {} unless smtp_configured?

    {
      address: ENV.fetch(SMTP_ENV_KEYS[:address], nil),
      port: ENV.fetch(SMTP_ENV_KEYS[:port], '587').to_i,
      user_name: ENV.fetch(SMTP_ENV_KEYS[:user_name], nil),
      password: ENV.fetch(SMTP_ENV_KEYS[:password], nil),
      domain: ENV.fetch(SMTP_ENV_KEYS[:domain], nil),
      from: ENV.fetch(SMTP_ENV_KEYS[:from], nil),
      authentication: ENV.fetch(SMTP_ENV_KEYS[:password], nil).present? ? :plain : nil,
      enable_starttls_auto: true,
      open_timeout: ENV.fetch('SMTP_OPEN_TIMEOUT', '15').to_i,
      read_timeout: ENV.fetch('SMTP_READ_TIMEOUT', '25').to_i
    }.compact_blank
  end

  # Storage is considered configured when S3_ATTACHMENTS_BUCKET, GCS_BUCKET, or
  # AZURE_CONTAINER is provided via ENV.
  def storage_configured?
    ENV.fetch('S3_ATTACHMENTS_BUCKET', nil).present? ||
      ENV.fetch('GCS_BUCKET', nil).present? ||
      ENV.fetch('AZURE_CONTAINER', nil).present?
  end

  # Returns the externally-configured storage service name.
  def storage_service
    if ENV.fetch('S3_ATTACHMENTS_BUCKET', nil).present?
      'aws_s3'
    elsif ENV.fetch('GCS_BUCKET', nil).present?
      'google'
    elsif ENV.fetch('AZURE_CONTAINER', nil).present?
      'azure'
    end
  end

  # Returns a display-friendly hash of the current storage configuration
  # sourced from ENV vars.
  def storage_settings
    return {} unless storage_configured?

    service = storage_service
    configs = storage_configs_for(service)

    return {} if configs.nil?

    { 'service' => service, 'configs' => configs.compact_blank }
  end

  def storage_configs_for(service)
    case service
    when 'aws_s3'
      {
        'access_key_id' => ENV.fetch(STORAGE_ENV_KEYS[:access_key_id], nil),
        'secret_access_key' => ENV.fetch(STORAGE_ENV_KEYS[:secret_access_key], nil),
        'region' => ENV.fetch(STORAGE_ENV_KEYS[:region], 'us-east-1'),
        'bucket' => ENV.fetch(STORAGE_ENV_KEYS[:bucket], nil),
        'endpoint' => ENV.fetch(STORAGE_ENV_KEYS[:endpoint], nil)
      }
    when 'google'
      {
        'bucket' => ENV.fetch('GCS_BUCKET', nil),
        'project' => ENV.fetch('GCS_PROJECT', nil)
      }
    when 'azure'
      {
        'storage_account_name' => ENV.fetch('AZURE_STORAGE_ACCOUNT_NAME', nil),
        'container' => ENV.fetch('AZURE_CONTAINER', nil)
      }
    end
  end
end
