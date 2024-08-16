# frozen_string_literal: true

class UpdateSubmissionAccountIdIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :submissions, %i[account_id id]
    remove_index :submissions, :account_id
  end
end
