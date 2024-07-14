# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_urls
#
#  id         :bigint           not null, primary key
#  events     :text             not null
#  sha1       :string           not null
#  url        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_webhook_urls_on_account_id  (account_id)
#  index_webhook_urls_on_sha1        (sha1)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class WebhookUrl < ApplicationRecord
  belongs_to :account

  attribute :events, :string, default: -> { [] }

  serialize :events, coder: JSON

  before_validation :set_sha1

  encrypts :url

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest(url)
  end
end
