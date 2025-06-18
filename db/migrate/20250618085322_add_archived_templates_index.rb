# frozen_string_literal: true

class AddArchivedTemplatesIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :templates, %i[account_id id], where: 'archived_at IS NOT NULL',
                                             name: 'index_templates_on_account_id_and_id_archived'
  end
end
