# frozen_string_literal: true

class CreateConsole1984Tables < ActiveRecord::Migration[7.0]
  def change
    create_table :console1984_sessions do |t|
      t.text :reason
      t.references :user, null: false, index: false
      t.timestamps

      t.index :created_at
      t.index %i[user_id created_at]
    end

    create_table :console1984_users do |t|
      t.string :username, null: false
      t.timestamps

      t.index [:username]
    end

    create_table :console1984_commands do |t|
      t.text :statements
      t.references :sensitive_access
      t.references :session, null: false, index: false
      t.timestamps

      t.index %i[session_id created_at sensitive_access_id], name: 'on_session_and_sensitive_chronologically'
    end

    create_table :console1984_sensitive_accesses do |t|
      t.text :justification
      t.references :session, null: false

      t.timestamps
    end
  end
end
