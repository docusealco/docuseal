# frozen_string_literal: true

class AddIndexOnSubmissionsCompletedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :submissions, %i[account_id completed_at],
              where: 'completed_at IS NOT NULL AND archived_at IS NULL',
              name: 'index_submissions_on_account_id_and_completed_at',
              if_not_exists: true

    return unless connection.supports_partial_index?

    add_index :submissions, %i[account_id id],
              where: 'completed_at IS NULL AND archived_at IS NULL',
              name: 'index_submissions_on_account_id_and_id_pending',
              if_not_exists: true
  end
end
