# frozen_string_literal: true

class PopulateSubmitterAccountId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction

  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'
    belongs_to :submission, class_name: 'MigrationSubmission'
  end

  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    MigrationSubmitter.where(account_id: nil).preload(:submission).find_each do |submitter|
      submitter.update_columns(account_id: submitter.submission.account_id)
    end

    if MigrationSubmitter.exists?(account_id: nil)
      MigrationSubmitter.where(account_id: nil).preload(:submission).find_each do |submitter|
        submitter.update_columns(account_id: submitter.submission.account_id)
      end
    end

    change_column_null :submitters, :account_id, false
  end

  def down
    nil
  end
end
