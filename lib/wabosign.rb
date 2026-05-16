# frozen_string_literal: true

module Wabosign
  PRODUCT_URL = ENV.fetch('PRODUCT_URL', 'https://sign.wabo.cc')
  PRODUCT_EMAIL_URL = ENV.fetch('PRODUCT_EMAIL_URL', PRODUCT_URL)
  NEWSLETTER_URL = "#{PRODUCT_URL}/newsletters".freeze
  ENQUIRIES_URL = "#{PRODUCT_URL}/enquiries".freeze
  PRODUCT_NAME = 'WaboSign'
  # AGPLv3 §7(b) upstream attribution — must remain visible in interactive UIs.
  UPSTREAM_NAME = 'DocuSeal'
  UPSTREAM_URL  = 'https://github.com/docusealco/docuseal'
  DEFAULT_APP_URL = ENV.fetch('APP_URL', 'http://localhost:3000')
  GITHUB_URL = 'https://github.com/wabolabs/wabosign'
  SUPPORT_EMAIL = 'wabosign@wabo.cc'
  HOST = ENV.fetch('HOST', 'localhost')
  AATL_CERT_NAME = 'wabosign_aatl'
  GOOGLE_CLIENT_ID = ENV.fetch('GOOGLE_CLIENT_ID', nil)
  GOOGLE_CLIENT_SECRET = ENV.fetch('GOOGLE_CLIENT_SECRET', nil)
  GOOGLE_ALLOWED_DOMAINS = ENV.fetch('GOOGLE_ALLOWED_DOMAINS', '')
                              .split(',').map(&:strip).reject(&:empty?).freeze
  GOOGLE_DEFAULT_ACCOUNT_ID = ENV.fetch('GOOGLE_DEFAULT_ACCOUNT_ID', nil)
  CONSOLE_URL = if Rails.env.development?
                  'http://console.localhost.io:3001'
                elsif ENV['MULTITENANT'] == 'true'
                  "https://console.#{HOST}"
                else
                  "https://console.#{HOST}"
                end
  CLOUD_URL = if Rails.env.development?
                'http://localhost:3000'
              else
                PRODUCT_URL
              end
  CDN_URL = if Rails.env.development?
              'http://localhost:3000'
            elsif ENV['MULTITENANT'] == 'true'
              "https://cdn.#{HOST}"
            else
              "https://cdn.#{HOST}"
            end

  CERTS = JSON.parse(ENV.fetch('CERTS', '{}'))
  TIMESERVER_URL = ENV.fetch('TIMESERVER_URL', nil)
  VERSION_FILE_PATH = Rails.root.join('.version')
  VERSION_FILE2_PATH = Rails.public_path.join('version')

  DEFAULT_URL_OPTIONS = {
    host: HOST,
    protocol: ENV['FORCE_SSL'].present? ? 'https' : 'http'
  }.freeze

  module_function

  def version
    @version ||=
      if VERSION_FILE_PATH.exist?
        VERSION_FILE_PATH.read.strip
      elsif VERSION_FILE2_PATH.exist?
        VERSION_FILE2_PATH.each_line.first.to_s.strip
      end
  end

  def multitenant?
    ENV['MULTITENANT'] == 'true'
  end

  def advanced_formats?
    multitenant?
  end

  def demo?
    ENV['DEMO'] == 'true'
  end

  def active_storage_public?
    ENV['ACTIVE_STORAGE_PUBLIC'] == 'true'
  end

  def default_pkcs
    return if Wabosign::CERTS['enabled'] == false

    @default_pkcs ||= GenerateCertificate.load_pkcs(Wabosign::CERTS)
  end

  def fulltext_search?
    return @fulltext_search unless @fulltext_search.nil?

    @fulltext_search =
      if SearchEntry.table_exists?
        Wabosign.multitenant? || AccountConfig.exists?(key: :fulltext_search, value: true)
      else
        false
      end
  end

  def enable_pwa?
    true
  end

  def pdf_format
    @pdf_format ||= ENV['PDF_FORMAT'].to_s.downcase
  end

  def trusted_certs
    @trusted_certs ||=
      ENV['TRUSTED_CERTS'].to_s.gsub('\\n', "\n").split("\n\n").map do |base64|
        OpenSSL::X509::Certificate.new(base64)
      end
  end

  def default_url_options
    return DEFAULT_URL_OPTIONS if multitenant?

    @default_url_options ||= begin
      value = EncryptedConfig.find_by(key: EncryptedConfig::APP_URL_KEY)&.value if ENV['APP_URL'].blank?
      value ||= DEFAULT_APP_URL
      url = Addressable::URI.parse(value)
      { host: url.host, port: url.port, protocol: url.scheme }
    end
  end

  def product_name
    PRODUCT_NAME
  end

  def refresh_default_url_options!
    @default_url_options = nil
  end

  def google_sso_enabled?
    GOOGLE_CLIENT_ID.present? && GOOGLE_CLIENT_SECRET.present?
  end

  def google_domain_allowed?(hd)
    return false if hd.blank?
    return true if GOOGLE_ALLOWED_DOMAINS.empty?

    GOOGLE_ALLOWED_DOMAINS.include?(hd)
  end
end

if Wabosign.google_sso_enabled? && Wabosign::GOOGLE_ALLOWED_DOMAINS.empty?
  Rails.logger.warn(
    '[Wabosign] Google SSO is enabled but GOOGLE_ALLOWED_DOMAINS is empty — ' \
    'any Google account will be permitted to sign in.'
  )
end
