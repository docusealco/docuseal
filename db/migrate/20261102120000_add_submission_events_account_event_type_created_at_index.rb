# frozen_string_literal: true

class AddSubmissionEventsAccountEventTypeCreatedAtIndex < ActiveRecord::Migration[8.1]
  def change
    return unless ENV['MULTITENANT'] == 'true'

    add_index :submission_events, %i[account_id created_at],
              where: "event_type = 'start_kba'",
              if_not_exists: true,
              name: 'index_submission_events_on_account_created_at_start_kba'
  end
end
