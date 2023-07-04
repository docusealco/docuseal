# frozen_string_literal: true

class CreateTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :templates do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :name, null: false
      t.text :schema, null: false
      t.text :fields, null: false
      t.text :submitters, null: false

      t.references :author, null: false, foreign_key: { to_table: :users }, index: true
      t.references :account, null: false, foreign_key: true, index: true

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
