# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id         :bigint           not null, primary key
#  sha256     :text             not null
#  token      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_access_tokens_on_sha256   (sha256) UNIQUE
#  index_access_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class AccessToken < ApplicationRecord
  TOKEN_LENGTH = 43

  belongs_to :user

  before_validation :set_sha256

  attribute :token, :string, default: -> { SecureRandom.base58(TOKEN_LENGTH) }

  encrypts :token

  private

  def set_sha256
    self.sha256 = Digest::SHA256.hexdigest(token)
  end
end
