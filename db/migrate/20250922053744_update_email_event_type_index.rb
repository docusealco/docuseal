# frozen_string_literal: true

class UpdateEmailEventTypeIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :email_events, :email, where: "event_type IN ('bounce', 'soft_bounce', 'complaint', 'soft_complaint')",
                                        name: 'index_email_events_on_email_event_types'

    add_index :email_events, :email,
              where: "event_type IN ('bounce', 'soft_bounce', 'permanent_bounce', 'complaint', 'soft_complaint')",
              name: 'index_email_events_on_email_event_types'
  end
end
