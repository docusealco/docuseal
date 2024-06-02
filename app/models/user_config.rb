# frozen_string_literal: true

# == Schema Information
#
# Table name: user_configs
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
#  index_user_configs_on_user_id          (user_id)
#  index_user_configs_on_user_id_and_key  (user_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserConfig < ApplicationRecord
  SIGNATURE_KEY = 'signature'
  INITIALS_KEY = 'initials'
  RECEIVE_COMPLETED_EMAIL = 'receive_completed_email'

  belongs_to :user

  serialize :value, coder: JSON
end
