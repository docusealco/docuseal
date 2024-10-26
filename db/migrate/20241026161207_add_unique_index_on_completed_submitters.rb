# frozen_string_literal: true

class AddUniqueIndexOnCompletedSubmitters < ActiveRecord::Migration[7.2]
  def change
    remove_index :completed_submitters, :submitter_id
    add_index :completed_submitters, :submitter_id, unique: true
  end
end
