# frozen_string_literal: true

class CreateTemplateSharings < ActiveRecord::Migration[7.1]
  def change
    create_table :template_sharings do |t|
      t.references :template, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: false, index: false
      t.string :ability, null: false

      t.index %i[account_id template_id], unique: true

      t.timestamps
    end
  end
end
