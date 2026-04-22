# frozen_string_literal: true

# External configuration loaded from environment variables.
# Currently exposes SMTP settings; additional external config concerns can be
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
end
