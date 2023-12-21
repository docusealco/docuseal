# frozen_string_literal: true

# == Schema Information
#
# Table name: email_messages
#
#  id         :bigint           not null, primary key
#  body       :text             not null
#  sha1       :string           not null
#  subject    :text             not null
#  uuid       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  author_id  :bigint           not null
#
# Indexes
#
#  index_email_messages_on_account_id  (account_id)
#  index_email_messages_on_sha1        (sha1)
#  index_email_messages_on_uuid        (uuid)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (author_id => users.id)
#
class EmailMessage < ApplicationRecord
  belongs_to :author, class_name: 'User'
  belongs_to :account

  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  before_validation :set_sha1, on: :create

  def set_sha1
    self.sha1 = Digest::SHA1.hexdigest({ subject:, body: }.to_json)
  end
end
