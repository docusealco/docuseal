# frozen_string_literal: true

class AddSubmittersCompletedAtPartialIndex < ActiveRecord::Migration[8.1]
  def up
    add_index :submitters, %i[account_id completed_at], where: 'completed_at IS NOT NULL', if_not_exists: true
  end

  def down
    remove_index :submitters, %i[account_id completed_at], if_exists: true
  end
end
