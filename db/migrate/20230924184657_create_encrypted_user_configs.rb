# frozen_string_literal: true

class CreateEncryptedUserConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :encrypted_user_configs do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :key, null: false
      t.text :value, null: false

      t.index %i[user_id key], unique: true

      t.timestamps
    end
  end
end
