# frozen_string_literal: true

# == Schema Information
#
# Table name: email_events
#
#  id             :bigint           not null, primary key
#  data           :text             not null
#  email          :string           not null
#  emailable_type :string           not null
#  event_datetime :datetime         not null
#  event_type     :string           not null
#  tag            :string           not null
#  created_at     :datetime         not null
#  account_id     :bigint           not null
#  emailable_id   :bigint           not null
#  message_id     :string           not null
#
# Indexes
#
#  index_email_events_on_account_id  (account_id)
#  index_email_events_on_email       (email)
#  index_email_events_on_emailable   (emailable_type,emailable_id)
#  index_email_events_on_message_id  (message_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class EmailEvent < ApplicationRecord
  belongs_to :emailable, polymorphic: true
  belongs_to :account

  attribute :data, :string, default: -> { {} }

  serialize :data, coder: JSON

  before_validation :maybe_set_account, on: :create

  def maybe_set_account
    self.account ||= emailable.account
  end
end
