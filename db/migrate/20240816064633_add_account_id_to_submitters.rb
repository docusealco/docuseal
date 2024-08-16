# frozen_string_literal: true

class AddAccountIdToSubmitters < ActiveRecord::Migration[7.1]
  def change
    add_reference :submitters, :account, index: false, null: true

    add_index :submitters, %i[account_id id]
  end
end
