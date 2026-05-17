# frozen_string_literal: true

# Boot-time seeder for the self-hosted / embedded deployment. Reads
# DOCUSEAL_* env vars and idempotently upserts the rows that the upstream
# /setup wizard would otherwise create through the UI:
#
#   * Account            (organisation row)
#   * User               (admin login)
#   * AccessToken        (API key)
#   * EncryptedConfig    (APP_URL — required by url helpers)
#   * WebhookUrl         (callback target subscribed to a fixed event set)
#
# Works in development and production. Safe to run on every boot:
#
#   * Skips entirely when DOCUSEAL_ADMIN_EMAIL / DOCUSEAL_ADMIN_PASSWORD
#     are absent (lets the human /setup flow run unmolested if you'd
#     rather provision by hand).
#   * Resilient to a fresh DB (`db:create` before `db:migrate`): catches
#     `ActiveRecord::NoDatabaseError` and `ActiveRecord::StatementInvalid`
#     so the boot doesn't crash before migrations have a chance to run.
#   * Each upsert is keyed on a natural identifier (email / sha1(url))
#     so re-runs do not duplicate.
#   * `AccessToken#token` is only rewritten when DOCUSEAL_API_KEY is set
#     AND differs from what's already stored — otherwise an existing
#     auto-generated token stays put.
Rails.application.config.after_initialize do
  email    = ENV['DOCUSEAL_ADMIN_EMAIL'].to_s.strip
  password = ENV['DOCUSEAL_ADMIN_PASSWORD'].to_s
  next if email.empty? || password.empty?

  begin
    next unless ActiveRecord::Base.connection.data_source_exists?('users')
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished,
         ActiveRecord::StatementInvalid, PG::Error
    next
  end

  begin
    ActiveRecord::Base.transaction do
      account = Account.first || Account.create!(
        name:     ENV.fetch('DOCUSEAL_ACCOUNT_NAME', 'DocuSeal'),
        timezone: ENV.fetch('DOCUSEAL_TIMEZONE',    'UTC'),
        locale:   ENV.fetch('DOCUSEAL_LOCALE',      'en-US')
      )

      user = User.find_or_initialize_by(email: email)
      user.account     = account
      user.role        = User::ADMIN_ROLE
      user.first_name  = ENV.fetch('DOCUSEAL_ADMIN_FIRST_NAME', 'Admin')
      user.last_name   = ENV.fetch('DOCUSEAL_ADMIN_LAST_NAME',  '')
      user.password    = password if user.new_record? || user.encrypted_password.blank?
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!) && !user.confirmed?
      user.save!

      desired_token = ENV['DOCUSEAL_API_KEY'].to_s.strip
      if desired_token.present?
        token = user.access_tokens.first_or_initialize
        if token.new_record? || token.token != desired_token
          token.token = desired_token
          token.save!
        end
      end

      app_url = ENV.fetch('DOCUSEAL_APP_URL', "http://localhost:#{ENV.fetch('PORT', 3000)}")
      app_url_config = account.encrypted_configs.find_or_initialize_by(key: EncryptedConfig::APP_URL_KEY)
      if app_url_config.new_record? || app_url_config.value != app_url
        app_url_config.value = app_url
        app_url_config.save!
      end

      if account.encrypted_configs.find_by(key: EncryptedConfig::ESIGN_CERTS_KEY).blank?
        account.encrypted_configs.create!(
          key:   EncryptedConfig::ESIGN_CERTS_KEY,
          value: GenerateCertificate.call.transform_values(&:to_pem)
        )
      end

      if SearchEntry.table_exists? &&
         account.account_configs.find_by(key: 'fulltext_search').blank?
        account.account_configs.create!(key: :fulltext_search, value: true)
      end

      webhook_url = ENV['DOCUSEAL_WEBHOOK_URL'].to_s.strip
      if webhook_url.present?
        events = ENV.fetch('DOCUSEAL_WEBHOOK_EVENTS', 'form.completed,template.created')
                    .split(',').map(&:strip).reject(&:empty?)
        row = account.webhook_urls.find_or_initialize_by(sha1: Digest::SHA1.hexdigest(webhook_url))
        row.url    = webhook_url
        row.events = events
        row.save!
      end

      Docuseal.refresh_default_url_options! if defined?(Docuseal) && Docuseal.respond_to?(:refresh_default_url_options!)
    end
  rescue StandardError => e
    Rails.logger.warn("[env_seed] skipped: #{e.class}: #{e.message}")
  end
end
