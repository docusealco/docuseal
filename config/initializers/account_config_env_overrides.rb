# frozen_string_literal: true

# Seeds DOCUSEAL_CONFIG_* env overrides into every existing account on boot.
# New accounts receive overrides via Account#after_create_commit.
#
# Runs only when at least one override env var is set and the accounts table is ready.
Rails.application.config.after_initialize do
  next if Rails.env.test?
  next unless ActiveRecord::Base.connection.data_source_exists?('accounts')
  next if Account.env_config_overrides.empty?

  Account.find_each(&:apply_env_config_overrides)
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
  Rails.logger.warn("[account_config_env_overrides] skipped: #{e.class}: #{e.message}")
end
