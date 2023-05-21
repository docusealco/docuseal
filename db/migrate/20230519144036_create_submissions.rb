# frozen_string_literal: true

class CreateSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :submissions do |t|
      t.string :email, null: false, index: true
      t.string :slug, null: false, index: { unique: true }
      t.references :flow, null: false, foreign_key: true, index: true
      t.string :values, null: false
      t.string :ua
      t.string :ip

      t.datetime :sent_at
      t.datetime :opened_at
      t.datetime :completed_at
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
