# frozen_string_literal: true

# == Schema Information
#
# Table name: encrypted_user_configs
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  value      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_encrypted_user_configs_on_user_id          (user_id)
#  index_encrypted_user_configs_on_user_id_and_key  (user_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class EncryptedUserConfig < ApplicationRecord
  belongs_to :user

  encrypts :value

  serialize :value, coder: JSON
end
