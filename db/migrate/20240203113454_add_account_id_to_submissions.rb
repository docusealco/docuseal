# frozen_string_literal: true

class AddAccountIdToSubmissions < ActiveRecord::Migration[7.1]
  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  class MigrationAccount < ApplicationRecord
    self.table_name = 'accounts'
  end

  def change
    add_reference :submissions, :account, index: true, null: true

    MigrationAccount.all.each do |account|
      MigrationSubmission.where(template_id: MigrationTemplate.where(account_id: account.id).select(:id))
                         .update_all(account_id: account.id)
    end

    change_column_null :submissions, :account_id, false
  end
end
