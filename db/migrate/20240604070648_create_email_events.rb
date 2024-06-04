# frozen_string_literal: true

class CreateEmailEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :email_events do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :emailable, polymorphic: true, index: true, null: false
      t.string :message_id, null: false, index: true
      t.string :tag, null: false
      t.string :event_type, null: false
      t.string :email, null: false
      t.text :data, null: false
      t.datetime :event_datetime, null: false
      t.datetime :created_at, null: false
    end
  end
end
