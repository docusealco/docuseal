# frozen_string_literal: true

class CreateWebhookEventsAndAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_events do |t|
      t.string :uuid, null: false
      t.bigint :webhook_url_id, null: false
      t.bigint :account_id, null: false
      t.bigint :record_id, null: false
      t.string :record_type, null: false
      t.string :event_type, null: false
      t.string :status, null: false

      t.index %i[uuid webhook_url_id], unique: true
      t.index %i[webhook_url_id id]
      t.index %i[webhook_url_id id], where: "status = 'error'", name: 'index_webhook_events_error'

      t.timestamps
    end

    create_table :webhook_attempts do |t|
      t.bigint :webhook_event_id, null: false, index: true
      t.text :response_body
      t.integer :response_status_code, null: false
      t.integer :attempt, null: false

      t.timestamps
    end
  end
end
