# frozen_string_literal: true

class CreateAccountLinkedAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :account_linked_accounts do |t|
      t.references :account, null: false, foreign_key: true
      t.references :linked_account, null: false, foreign_key: { to_table: :accounts }
      t.text :account_type, null: false

      t.index %i[account_id linked_account_id], unique: true

      t.timestamps
    end
  end
end
