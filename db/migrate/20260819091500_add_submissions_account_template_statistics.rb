# frozen_string_literal: true

class AddSubmissionsAccountTemplateStatistics < ActiveRecord::Migration[8.1]
  def up
    return unless adapter_name == 'PostgreSQL'

    execute <<~SQL.squish
      CREATE STATISTICS IF NOT EXISTS submissions_account_template_stats (dependencies, ndistinct)
      ON account_id, template_id FROM submissions
    SQL
  end

  def down
    return unless adapter_name == 'PostgreSQL'

    execute 'DROP STATISTICS IF EXISTS submissions_account_template_stats'
  end
end
