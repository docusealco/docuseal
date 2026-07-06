# frozen_string_literal: true

# == Schema Information
#
# Table name: email_message_assets
#
#  id         :bigint           not null, primary key
#  data       :text             not null
#  sha1       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_email_message_assets_on_account_id_and_sha1  (account_id,sha1) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class EmailMessageAsset < ApplicationRecord
  belongs_to :account

  before_validation :set_sha1, on: :create

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(data.to_s)
  end
end
