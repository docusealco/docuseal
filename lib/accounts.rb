# frozen_string_literal: true

module Accounts
  module_function

  def create_duplicate(account)
    new_account = account.dup

    new_user = account.users.first.dup

    new_user.uuid = SecureRandom.uuid
    new_user.account = new_account
    new_user.encrypted_password = SecureRandom.hex
    new_user.email = "#{SecureRandom.hex}@docuseal.co"

    account.templates.each do |template|
      new_template = template.dup

      new_template.account = new_account
      new_template.slug = SecureRandom.base58(14)

      new_template.archived_at = nil
      new_template.save!

      Templates::CloneAttachments.call(template: new_template, original_template: template)
    end

    new_user.save!(validate: false)
    new_account.templates.update_all(folder_id: new_account.default_template_folder.id)

    new_account
  end

  def users_count(account)
    rel = User.where(account_id: account.id).or(
      User.where(account_id: account.account_linked_accounts
                                           .where.not(account_type: :testing)
                                           .select(:linked_account_id))
    )

    rel.where.not(account: account.linked_accounts.where.not(archived_at: nil))
       .where.not(role: :integration).active.count
  end

  def find_or_create_testing_user(account)
    user = User.where(role: :admin).order(:id).find_by(account: account.testing_accounts)

    return user if user

    testing_account = account.dup.tap { |a| a.name = "Testing - #{a.name}" }
    testing_account.uuid = SecureRandom.uuid

    ApplicationRecord.transaction do
      account.testing_accounts << testing_account

      testing_account.users.create!(
        email: account.users.order(:id).first.email.sub('@', '+test@'),
        first_name: 'Testing',
        last_name: 'Environment',
        password: SecureRandom.hex,
        role: :admin
      )
    end
  end

  def create_default_template(account)
    template = Template.find(1)

    new_template = Template.find(1).dup
    new_template.account_id = account.id
    new_template.slug = SecureRandom.base58(14)
    new_template.folder = account.default_template_folder

    new_template.save!

    Templates::CloneAttachments.call(template: new_template, original_template: template)

    new_template
  end

  def load_webhook_url(account)
    load_webhook_config(account)&.value.presence
  end

  def load_webhook_config(account)
    configs = account.encrypted_configs.find_by(key: EncryptedConfig::WEBHOOK_URL_KEY)

    if !configs && !Docuseal.multitenant? && !account.testing?
      configs = Account.order(:id).first.encrypted_configs.find_by(key: EncryptedConfig::WEBHOOK_URL_KEY)
    end

    configs
  end

  def load_webhook_preferences(account)
    configs = account.account_configs.find_by(key: AccountConfig::WEBHOOK_PREFERENCES_KEY)

    unless Docuseal.multitenant?
      configs ||= Account.order(:id).first.account_configs.find_by(key: AccountConfig::WEBHOOK_PREFERENCES_KEY)
    end

    configs&.value.presence || {}
  end

  def load_signing_pkcs(account)
    cert_data =
      if Docuseal.multitenant?
        data = EncryptedConfig.find_by(account:, key: EncryptedConfig::ESIGN_CERTS_KEY)&.value

        return Docuseal.default_pkcs if data.blank?

        data
      else
        EncryptedConfig.find_by(account:, key: EncryptedConfig::ESIGN_CERTS_KEY)&.value ||
          EncryptedConfig.find_by(key: EncryptedConfig::ESIGN_CERTS_KEY).value
      end

    if (default_cert = cert_data['custom']&.find { |e| e['status'] == 'default' })
      OpenSSL::PKCS12.new(Base64.urlsafe_decode64(default_cert['data']), default_cert['password'].to_s)
    else
      GenerateCertificate.load_pkcs(cert_data)
    end
  end

  def load_timeserver_url(account)
    if Docuseal.multitenant?
      Docuseal::TIMESERVER_URL
    else
      url = EncryptedConfig.find_by(account:, key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)&.value

      unless Docuseal.multitenant?
        url ||=
          Account.order(:id).first.encrypted_configs.find_by(key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)&.value
      end

      url
    end.presence
  end

  def can_send_emails?(_account, **_params)
    return true if Docuseal.multitenant?
    return true if ENV['SMTP_ADDRESS'].present?

    EncryptedConfig.exists?(key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def normalize_timezone(timezone)
    tzinfo = TZInfo::Timezone.get(ActiveSupport::TimeZone::MAPPING[timezone] || timezone)

    ::ActiveSupport::TimeZone.all.find { |e| e.tzinfo == tzinfo }&.name || timezone
  rescue TZInfo::InvalidTimezoneIdentifier
    'UTC'
  end
end
