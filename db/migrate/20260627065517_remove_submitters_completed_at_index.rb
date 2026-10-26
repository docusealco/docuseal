# frozen_string_literal: true

class RemoveSubmittersCompletedAtIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :submitters, %i[completed_at account_id], if_exists: true
  end

  def down
    add_index :submitters, %i[completed_at account_id], if_not_exists: true
  end
end
