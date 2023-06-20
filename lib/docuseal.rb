# frozen_string_literal: true

module Docuseal
  DEFAULT_APP_URL = 'http://localhost:3000'

  module_function

  def default_url_options
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
