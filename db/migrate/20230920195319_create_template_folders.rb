# frozen_string_literal: true

class CreateTemplateFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :template_folders do |t|
      t.string :name, null: false

      t.references :author, null: false, foreign_key: { to_table: :users }, index: true
      t.references :account, null: false, foreign_key: true, index: true

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
