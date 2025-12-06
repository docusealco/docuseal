# frozen_string_literal: true

class AddCompletedAtIndexToCompletedSubmitters < ActiveRecord::Migration[8.0]
  def change
    add_index :completed_submitters, %i[account_id completed_at],
              name: 'index_completed_submitters_on_account_id_and_completed_at'
    remove_index :completed_submitters, :account_id
  end
end
