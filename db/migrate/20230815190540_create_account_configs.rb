# frozen_string_literal: true

class CreateAccountConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :account_configs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :key, null: false
      t.text :value, null: false

      t.index %i[account_id key], unique: true

      t.timestamps
    end
  end
end
