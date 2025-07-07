# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_attempts
#
#  id                   :bigint           not null, primary key
#  attempt              :integer          not null
#  response_body        :text
#  response_status_code :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  webhook_event_id     :bigint           not null
#
# Indexes
#
#  index_webhook_attempts_on_webhook_event_id  (webhook_event_id)
#
class WebhookAttempt < ApplicationRecord
  belongs_to :webhook_event

  def success?
    [2, 3].include?(response_status_code.to_i / 100)
  end
end
