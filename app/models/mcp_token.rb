# frozen_string_literal: true

# == Schema Information
#
# Table name: mcp_tokens
#
#  id           :bigint           not null, primary key
#  archived_at  :datetime
#  name         :string           not null
#  sha256       :string           not null
#  token_prefix :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_mcp_tokens_on_sha256   (sha256) UNIQUE
#  index_mcp_tokens_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class McpToken < ApplicationRecord
  TOKEN_LENGTH = 43

  belongs_to :user

  before_validation :set_sha256_and_token_prefix, on: :create

  attribute :token, :string, default: -> { SecureRandom.base58(TOKEN_LENGTH) }

  scope :active, -> { where(archived_at: nil) }

  private

  def set_sha256_and_token_prefix
    self.sha256 = Digest::SHA256.hexdigest(token)
    self.token_prefix = token[0, 5]
  end
end
