# frozen_string_literal: true

module Docuseal
  PRODUCT_URL = 'https://www.docuseal.co'
  PRODUCT_NAME = 'DocuSeal'
  DEFAULT_APP_URL = 'http://localhost:3000'

  CERTS = JSON.parse(ENV.fetch('CERTS', '{}'))

  DEFAULT_URL_OPTIONS = {
    host: ENV.fetch('HOST', 'localhost'),
    protocol: ENV['FORCE_SSL'] == 'true' ? 'https' : 'http'
  }.freeze

  module_function

  def multitenant?
    ENV['MULTITENANT'] == 'true'
  end

  def default_url_options
    return DEFAULT_URL_OPTIONS if multitenant?

    @default_url_options ||= begin
      value = EncryptedConfig.find_by(key: EncryptedConfig::APP_URL_KEY)&.value
      value ||= DEFAULT_APP_URL
      url = Addressable::URI.parse(value)
      { host: url.host, port: url.port, protocol: url.scheme }
    end
  end

  def refresh_default_url_options!
    @default_url_options = nil
  end
end
