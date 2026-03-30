# frozen_string_literal: true

class CreateSubmitterVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :submitter_versions do |t|
      t.references :submitter, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :email
      t.string :name
      t.string :phone

      t.timestamps
    end

    add_index :submitter_versions, :slug
  end
end
