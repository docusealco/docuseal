# frozen_string_literal: true

class PopulateSubmissionCompletedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    max_id = MigrationSubmission.maximum(:id)

    return unless max_id

    max_completed_at =
      Arel::Nodes::Grouping.new(
        Submitter.arel_table.project(Submitter.arel_table[:completed_at].maximum)
                 .where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id]))
                 .ast
      )

    (1..max_id).step(10_000) do |start_id|
      range = start_id...(start_id + 10_000)

      incomplete_submitter =
        Submitter.where(completed_at: nil, submission_id: range)
                 .where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id]))
                 .select(1)

      MigrationSubmission.where(completed_at: nil, id: range)
                .where.not(incomplete_submitter.arel.exists)
                .update_all(completed_at: max_completed_at)
    end
  end

  def down
    nil
  end
end
