# frozen_string_literal: true

# == Schema Information
#
# Table name: email_events
#
#  id             :integer          not null, primary key
#  data           :text             not null
#  email          :string           not null
#  emailable_type :string           not null
#  event_datetime :datetime         not null
#  event_type     :string           not null
#  tag            :string           not null
#  created_at     :datetime         not null
#  account_id     :integer          not null
#  emailable_id   :integer          not null
#  message_id     :string           not null
#
# Indexes
#
#  index_email_events_on_account_id_and_event_datetime  (account_id,event_datetime)
#  index_email_events_on_email                          (email)
#  index_email_events_on_email_event_types              (email) WHERE event_type IN ('bounce', 'soft_bounce', 'complaint', 'soft_complaint')
#  index_email_events_on_emailable                      (emailable_type,emailable_id)
#  index_email_events_on_message_id                     (message_id)
#
# Foreign Keys
#
#  account_id  (account_id => accounts.id)
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
