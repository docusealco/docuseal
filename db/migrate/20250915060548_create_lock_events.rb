# frozen_string_literal: true

class CreateLockEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :lock_events do |t|
      t.string :key, index: true, null: false
      t.string :event_name, null: false

      t.index %i[event_name key], unique: adapter_name != 'Mysql2', where: "event_name IN ('start', 'complete')"

      t.timestamps
    end
  end
end
