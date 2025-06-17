# frozen_string_literal: true

class AddSubmissionsTemplateIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :submissions, %i[account_id template_id id], where: 'archived_at IS NULL'
  end
end
