# frozen_string_literal: true

class AddVisibilityToTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :templates, :visibility, :string, default: 'private', null: false
    add_index :templates, %i[account_id visibility]
  end
end
