# frozen_string_literal: true

class CreateDocumentMetadata < ActiveRecord::Migration[8.1]
  def change
    create_table :document_metadata do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :blob_checksum, null: false
      t.text :text_runs, null: false

      t.datetime :created_at, null: false
    end

    add_index :document_metadata, %i[account_id blob_checksum], unique: true
  end
end
