# frozen_string_literal: true

module Wabosign
  PRODUCT_URL = ENV.fetch('PRODUCT_URL', 'https://sign.wabo.cc')
  PRODUCT_EMAIL_URL = ENV.fetch('PRODUCT_EMAIL_URL', PRODUCT_URL)
  PRODUCT_NAME = 'WaboSign'
  # AGPLv3 §7(b) upstream attribution — must remain visible in interactive UIs.
  UPSTREAM_NAME = 'DocuSeal'
  UPSTREAM_URL  = 'https://github.com/docusealco/docuseal'
  DEFAULT_APP_URL = ENV.fetch('APP_URL', 'http://localhost:3000')
  GITHUB_URL = 'https://github.com/wabolabs/wabosign'
  SUPPORT_EMAIL = 'wabosign@wabo.cc'
  HOST = ENV.fetch('HOST', 'localhost')
  AATL_CERT_NAME = 'wabosign_aatl'
  GOOGLE_DEFAULT_ACCOUNT_ID = ENV.fetch('GOOGLE_DEFAULT_ACCOUNT_ID', nil)
  NEWSLETTER_URL = "#{PRODUCT_URL}/newsletters".freeze
  ENQUIRIES_URL = "#{PRODUCT_URL}/enquiries".freeze
  DISCORD_URL = 'https://discord.gg/qygYCDGck9'
  TWITTER_URL = 'https://twitter.com/docusealco'
  TWITTER_HANDLE = '@docusealco'
  CHATGPT_URL = "#{PRODUCT_URL}/chat".freeze
  CONSOLE_URL = if Rails.env.development?
                  'http://console.localhost.io:3001'
                elsif ENV['MULTITENANT'] == 'true'
                  "https://console.#{HOST}"
                else
                  'https://console.docuseal.com'
                end
  CLOUD_URL = if Rails.env.development?
                'http://localhost:3000'
              else
                'https://docuseal.com'
              end
  CDN_URL = if Rails.env.development?
              'http://localhost:3000'
            elsif ENV['MULTITENANT'] == 'true'
              "https://cdn.#{HOST}"
            else
              'https://cdn.docuseal.com'
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

  # Returns the account's custom brand name (if set), the deployment's
  # default-account brand (for anonymous surfaces like the landing page,
  # PWA manifest, or og:title), or PRODUCT_NAME as the ultimate fallback.
  # Never overrides Wabosign::UPSTREAM_NAME — the AGPL §7(b) DocuSeal
  # credit in _powered_by, _email_attribution, and completed.vue stays
  # untouched.
  def branded_product_name(account = nil)
    account&.brand_name.presence ||
      default_brand_account&.brand_name.presence ||
      PRODUCT_NAME
  end

  # The deployment-wide fallback account whose brand name is used for
  # anonymous surfaces (no current_account in scope). Single-tenant
  # installs have exactly one account; multi-tenant picks the oldest.
  # Not memoized: the underlying query is fast and memoization would
  # need cache invalidation on every personalization save.
  def default_brand_account
    Account.where(archived_at: nil).order(:created_at).first
  rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
    nil
  end

  def refresh_default_url_options!
    @default_url_options = nil
  end

  # Returns the live Google SSO credentials, merging ENV (priority) with the
  # `google_sso_configs` EncryptedConfig (UI fallback). Called at request
  # time by the Devise OmniAuth setup proc and the sign-in page partial.
  #
  # Shape: { client_id:, client_secret:, allowed_domains:, source: :env|:db|:none }
  def google_sso_credentials
    env_id = ENV.fetch('GOOGLE_CLIENT_ID', nil)
    env_secret = ENV.fetch('GOOGLE_CLIENT_SECRET', nil)
    if env_id.present? && env_secret.present?
      return {
        client_id: env_id,
        client_secret: env_secret,
        allowed_domains: ENV.fetch('GOOGLE_ALLOWED_DOMAINS', '')
                            .split(',').map(&:strip).reject(&:empty?),
        source: :env
      }
    end

    db_value = google_sso_db_value
    if db_value.is_a?(Hash) && db_value['enabled'] &&
       db_value['client_id'].to_s.present? && db_value['client_secret'].to_s.present?
      return {
        client_id: db_value['client_id'].to_s,
        client_secret: db_value['client_secret'].to_s,
        allowed_domains: Array(db_value['allowed_domains']).filter_map { |d| d.to_s.strip.presence },
        source: :db
      }
    end

    { client_id: nil, client_secret: nil, allowed_domains: [], source: :none }
  end

  def google_sso_db_value
    return nil unless defined?(EncryptedConfig) && EncryptedConfig.table_exists?

    EncryptedConfig.find_by(key: EncryptedConfig::GOOGLE_SSO_KEY)&.value
  rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished
    nil
  end

  def google_sso_enabled?
    creds = google_sso_credentials
    creds[:client_id].present? && creds[:client_secret].present?
  end

  def google_domain_allowed?(hosted_domain)
    return false if hosted_domain.blank?

    domains = google_sso_credentials[:allowed_domains]
    return true if domains.empty?

    domains.include?(hosted_domain)
  end
end
