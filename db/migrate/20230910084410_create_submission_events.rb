# frozen_string_literal: true

class CreateSubmissionEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :submission_events do |t|
      t.references :submission, null: false, foreign_key: true, index: true
      t.references :submitter, null: true, foreign_key: true, index: true
      t.text :data, null: false
      t.string :event_type, null: false
      t.datetime :event_timestamp, null: false

      t.timestamps
    end
  end
end
