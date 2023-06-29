# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :timezone, null: false
      t.string :locale, null: false

      t.timestamps
    end
  end
end
