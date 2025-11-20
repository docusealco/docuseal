# frozen_string_literal: true

class AddSubmittersCompletedAtIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :submitters, %i[completed_at account_id]
  end
end
