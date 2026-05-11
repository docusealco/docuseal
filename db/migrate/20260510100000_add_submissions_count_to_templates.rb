# frozen_string_literal: true

class AddSubmissionsCountToTemplates < ActiveRecord::Migration[7.2]
  def up
    add_column :templates, :submissions_count, :integer, default: 0, null: false

    # Backfill existing counts
    execute <<~SQL.squish
      UPDATE templates
      SET submissions_count = (
        SELECT COUNT(*)
        FROM submissions
        WHERE submissions.template_id = templates.id
      )
    SQL
  end

  def down
    remove_column :templates, :submissions_count
  end
end