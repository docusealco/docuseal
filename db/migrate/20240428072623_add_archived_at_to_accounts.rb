# frozen_string_literal: true

class AddArchivedAtToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :archived_at, :datetime
  end
end
