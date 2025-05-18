# frozen_string_literal: true

class AccountAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :account_accesses do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: false, index: false

      t.index %i[account_id user_id], unique: true

      t.timestamps
    end
  end
end
