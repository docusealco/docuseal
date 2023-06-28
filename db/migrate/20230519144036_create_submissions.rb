# frozen_string_literal: true

class CreateSubmissions < ActiveRecord::Migration[7.0]
  def change
    create_table :submissions do |t|
      t.references :template, null: false, foreign_key: true, index: true
      t.references :created_by_user, null: true, foreign_key: { to_table: :users }, index: true

      t.datetime :deleted_at

      t.timestamps
    end
  end
end
