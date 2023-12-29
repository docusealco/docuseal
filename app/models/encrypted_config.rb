# frozen_string_literal: true

# == Schema Information
#
# Table name: encrypted_configs
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  value      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_encrypted_configs_on_account_id          (account_id)
#  index_encrypted_configs_on_account_id_and_key  (account_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class EncryptedConfig < ApplicationRecord
  CONFIG_KEYS = [
    FILES_STORAGE_KEY = 'active_storage',
    EMAIL_SMTP_KEY = 'action_mailer_smtp',
    ESIGN_CERTS_KEY = 'esign_certs',
    TIMESTAMP_SERVER_URL_KEY = 'timestamp_server_url',
    APP_URL_KEY = 'app_url',
    WEBHOOK_URL_KEY = 'webhook_url'
  ].freeze

  belongs_to :account

  encrypts :value

  serialize :value, coder: JSON
end
