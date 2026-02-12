# frozen_string_literal: true

class CreateDynamicDocumentVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :dynamic_document_versions do |t|
      t.references :dynamic_document, null: false, foreign_key: true, index: false
      t.string :sha1, null: false
      t.text :areas, null: false

      t.timestamps
    end

    add_index :dynamic_document_versions, %i[dynamic_document_id sha1], unique: true
  end
end
