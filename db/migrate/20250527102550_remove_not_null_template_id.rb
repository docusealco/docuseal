# frozen_string_literal: true

class RemoveNotNullTemplateId < ActiveRecord::Migration[8.0]
  def change
    change_column_null :submissions, :template_id, true
  end
end
