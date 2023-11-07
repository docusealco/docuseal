# frozen_string_literal: true

class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :token, null: false
      t.string :sha256, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
