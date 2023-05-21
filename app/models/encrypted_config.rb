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
  FILES_STORAGE_KEY = 'active_storage'
  EMAIL_SMTP_KEY = 'action_mailer_smtp'

  belongs_to :account

  encrypts :value

  serialize :value, JSON
end
