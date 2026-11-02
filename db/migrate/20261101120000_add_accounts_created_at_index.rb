# frozen_string_literal: true

class AddAccountsCreatedAtIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :accounts, :created_at, if_not_exists: true
  end
end
