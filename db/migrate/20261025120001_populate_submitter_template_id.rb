# frozen_string_literal: true

class PopulateSubmitterTemplateId < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    return if ENV['MULTITENANT'] == 'true'

    max_id = MigrationSubmitter.maximum(:id)

    return unless max_id

    submission_template_id =
      Arel::Nodes::Grouping.new(
        MigrationSubmission.arel_table.project(MigrationSubmission.arel_table[:template_id])
                           .where(MigrationSubmission.arel_table[:id].eq(MigrationSubmitter.arel_table[:submission_id]))
                           .ast
      )

    (1..max_id).step(10_000) do |start_id|
      MigrationSubmitter.where(template_id: nil, id: start_id...(start_id + 10_000))
                        .update_all(template_id: submission_template_id)
    end
  end

  def down
    nil
  end
end
