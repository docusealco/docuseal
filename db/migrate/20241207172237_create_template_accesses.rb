# frozen_string_literal: true

class CreateTemplateAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :template_accesses do |t|
      t.references :template, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: false, index: false

      t.index %i[template_id user_id], unique: true

      t.timestamps
    end
  end
end
