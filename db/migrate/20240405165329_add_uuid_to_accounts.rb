# frozen_string_literal: true

class AddUuidToAccounts < ActiveRecord::Migration[7.1]
  class MigrationAccount < ApplicationRecord
    self.table_name = 'accounts'
  end

  def up
    add_column :accounts, :uuid, :string

    MigrationAccount.all.each do |account|
      account.update_columns(uuid: SecureRandom.uuid)
    end

    add_index :accounts, :uuid, unique: true

    change_column_null :accounts, :uuid, false
  end

  def down
    drop_column :account, :uuid
  end
end
