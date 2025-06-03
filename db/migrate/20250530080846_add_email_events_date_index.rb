# frozen_string_literal: true

class AddEmailEventsDateIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :email_events, :account_id
    add_index :email_events, %i[account_id event_datetime]
  end
end
