# frozen_string_literal: true

class CreateSubmitters < ActiveRecord::Migration[7.0]
  def change
    create_table :submitters do |t|
      t.references :submission, null: false, foreign_key: true, index: true

      t.string :uuid, null: false
      t.string :email, null: false, index: true
      t.string :slug, null: false, index: { unique: true }
      t.text :values, null: false
      t.string :ua
      t.string :ip

      t.datetime :sent_at
      t.datetime :opened_at
      t.datetime :completed_at

      t.timestamps
    end
  end
end
