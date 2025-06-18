# frozen_string_literal: true

class AddSubmissionsTemplateIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :submissions, %i[account_id template_id id], where: 'archived_at IS NULL'
    add_index :submissions, %i[account_id template_id id],
              where: 'archived_at IS NOT NULL',
              name: 'index_submissions_on_account_id_and_template_id_and_id_archived'
  end
end
