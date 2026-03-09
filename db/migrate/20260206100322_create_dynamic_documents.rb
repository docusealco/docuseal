# frozen_string_literal: true

class CreateDynamicDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :dynamic_documents do |t|
      t.string :uuid, null: false
      t.references :template, null: false, foreign_key: true, index: true
      t.text :body, null: false
      t.text :head
      t.string :sha1, null: false

      t.timestamps
    end
  end
end
