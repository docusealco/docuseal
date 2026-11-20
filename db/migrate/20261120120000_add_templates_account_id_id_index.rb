# frozen_string_literal: true

class AddTemplatesAccountIdIdIndex < ActiveRecord::Migration[8.1]
  def up
    add_index :templates, %i[account_id id], if_not_exists: true, name: 'index_templates_on_account_id_and_id'
    remove_index :templates, :account_id, if_exists: true, name: 'index_templates_on_account_id'
  end

  def down
    add_index :templates, :account_id, if_not_exists: true, name: 'index_templates_on_account_id'
    remove_index :templates, %i[account_id id], if_exists: true, name: 'index_templates_on_account_id_and_id'
  end
end
