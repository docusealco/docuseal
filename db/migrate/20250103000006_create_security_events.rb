# frozen_string_literal: true

# Migration 6: Create security_events table
# Part of Winston's security event logging system
class CreateSecurityEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :security_events do |t|
      # User associated with the event (optional)
      t.references :user, null: true, foreign_key: true

      # Event details
      t.string :event_type, null: false
      t.string :ip_address, null: false
      t.jsonb :details, null: false, default: {}

      # Timestamps
      t.timestamps
    end

    # Indexes for filtering and performance
    add_index :security_events, :user_id
    add_index :security_events, :event_type
    add_index :security_events, :created_at
  end
end