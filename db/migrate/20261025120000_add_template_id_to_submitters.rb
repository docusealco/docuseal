# frozen_string_literal: true

class AddTemplateIdToSubmitters < ActiveRecord::Migration[8.1]
  def change
    add_column :submitters, :template_id, :bigint, if_not_exists: true
  end
end
