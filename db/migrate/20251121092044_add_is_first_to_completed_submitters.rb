# frozen_string_literal: true

class AddIsFirstToCompletedSubmitters < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/ThreeStateBooleanColumn
    add_column :completed_submitters, :is_first, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn

    add_index :completed_submitters, %i[account_id completed_at],
              where: 'is_first = TRUE',
              name: 'index_completed_submitters_account_id_completed_at_is_first'

    add_index :completed_submitters, :submission_id, unique: adapter_name != 'Mysql2',
                                                     where: 'is_first = TRUE'
  end
end
