# frozen_string_literal: true

class AddUuidToUsers < ActiveRecord::Migration[7.0]
  class MigrationUser < ApplicationRecord
    self.table_name = 'users'
  end

  def up
    add_column :users, :uuid, :string
    add_index :users, :uuid, unique: true

    MigrationUser.all.each do |user|
      user.update_columns(uuid: SecureRandom.uuid)
    end

    change_column_null :users, :uuid, false
  end

  def down
    drop_column :users, :uuid
  end
end
