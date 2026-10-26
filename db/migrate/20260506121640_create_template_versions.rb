# frozen_string_literal: true

class CreateTemplateVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :template_versions do |t|
      t.references :template, null: false, foreign_key: true, index: false
      t.references :account, null: false, foreign_key: true, index: true
      t.references :author, null: false, foreign_key: { to_table: :users }, index: true
      t.text :data, null: false
      t.string :sha1, null: false
      t.timestamps
    end

    add_index :template_versions, %i[template_id sha1], unique: true
  end
end
