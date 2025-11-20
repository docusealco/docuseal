# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_events
#
#  id             :bigint           not null, primary key
#  event_type     :string           not null
#  record_type    :string           not null
#  status         :string           not null
#  uuid           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  record_id      :bigint           not null
#  webhook_url_id :bigint           not null
#
# Indexes
#
#  index_webhook_events_error                       (webhook_url_id,id) WHERE ((status)::text = 'error'::text)
#  index_webhook_events_on_uuid_and_webhook_url_id  (uuid,webhook_url_id) UNIQUE
#  index_webhook_events_on_webhook_url_id_and_id    (webhook_url_id,id)
#
class WebhookEvent < ApplicationRecord
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  belongs_to :webhook_url, optional: true
  belongs_to :account, optional: true
  belongs_to :record, polymorphic: true, optional: true

  has_many :webhook_attempts, dependent: nil
end
