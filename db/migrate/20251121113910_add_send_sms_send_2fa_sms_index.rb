# frozen_string_literal: true

class AddSendSmsSend2faSmsIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :submission_events, %i[account_id created_at],
              where: "event_type IN ('send_sms', 'send_2fa_sms')",
              name: 'index_submissions_events_on_sms_event_types'
  end
end
