# frozen_string_literal: true

class RemoveCompletedSubmitterTemplateNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :completed_submitters, :template_id, true
  end
end
