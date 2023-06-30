# frozen_string_literal: true

module Accounts
  module_function

  def load_signing_certs(account)
    certs =
      if Docuseal.multitenant?
        Docuseal::CERTS
      else
        EncryptedConfig.find_by(account:, key: EncryptedConfig::ESIGN_CERTS_KEY).value
      end

    {
      cert: OpenSSL::X509::Certificate.new(certs['cert']),
      key: OpenSSL::PKey::RSA.new(certs['key']),
      sub_ca: OpenSSL::X509::Certificate.new(certs['sub_ca']),
      sub_key: OpenSSL::PKey::RSA.new(certs['sub_key']),
      root_ca: OpenSSL::X509::Certificate.new(certs['root_ca']),
      root_key: OpenSSL::PKey::RSA.new(certs['root_key'])
    }
  end

  def can_send_emails?(account)
    return true if Docuseal.multitenant?

    EncryptedConfig.exists?(account_id: account.id, key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def normalize_timezone(timezone)
    tzinfo = TZInfo::Timezone.get(ActiveSupport::TimeZone::MAPPING[timezone] || timezone)

    ::ActiveSupport::TimeZone.all.find { |e| e.tzinfo == tzinfo }&.name || timezone
  end
end
