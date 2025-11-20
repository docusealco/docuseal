# frozen_string_literal: true

class AddEmailEventsDateIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :email_events, %i[account_id event_datetime]
    remove_index :email_events, :account_id
  end
end
