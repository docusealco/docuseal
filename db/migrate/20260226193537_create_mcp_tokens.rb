# frozen_string_literal: true

class CreateMcpTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :mcp_tokens do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :sha256, null: false, index: { unique: true }
      t.string :token_prefix, null: false
      t.datetime :archived_at

      t.timestamps
    end
  end
end
