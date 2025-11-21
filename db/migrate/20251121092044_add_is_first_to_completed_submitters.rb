# frozen_string_literal: true

class AddIsFirstToCompletedSubmitters < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :completed_submitters, :is_first, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn

    add_index :completed_submitters, %i[account_id completed_at], where: 'is_first = TRUE'
    add_index :completed_submitters, :submission_id, unique: true, where: 'is_first = TRUE'
  end
end
