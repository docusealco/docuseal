# frozen_string_literal: true

module Accounts
  module_function

  def create_duplicate(account)
    new_account = account.dup

    new_user = account.users.first.dup

    new_user.account = new_account
    new_user.encrypted_password = SecureRandom.hex
    new_user.email = "#{SecureRandom.hex}@docuseal.co"

    account.templates.each do |template|
      new_template = template.dup

      new_template.account = new_account
      new_template.slug = SecureRandom.base58(14)

      new_template.save!

      Templates::CloneAttachments.call(template: new_template, original_template: template)
    end

    new_user.save!(validate: false)

    new_account
  end

  def create_default_template(account)
    template = Template.find(1)

    new_template = Template.find(1).dup
    new_template.account_id = account.id
    new_template.slug = SecureRandom.base58(14)

    new_template.save!

    Templates::CloneAttachments.call(template: new_template, original_template: template)

    new_template
  end

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
    return true if ENV['SMTP_ADDRESS'].present?

    EncryptedConfig.exists?(account_id: account.id, key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def normalize_timezone(timezone)
    tzinfo = TZInfo::Timezone.get(ActiveSupport::TimeZone::MAPPING[timezone] || timezone)

    ::ActiveSupport::TimeZone.all.find { |e| e.tzinfo == tzinfo }&.name || timezone
  end
end
