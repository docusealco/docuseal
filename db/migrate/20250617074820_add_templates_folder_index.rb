# frozen_string_literal: true

class AddTemplatesFolderIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :templates, %i[account_id folder_id id], where: 'archived_at IS NULL'
  end
end
