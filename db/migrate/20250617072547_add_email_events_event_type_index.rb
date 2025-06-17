# frozen_string_literal: true

class AddEmailEventsEventTypeIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :email_events, %i[event_type email],
              where: "event_type IN ('bounce', 'soft_bounce', 'complaint', 'soft_complaint')"
  end
end
