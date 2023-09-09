# frozen_string_literal: true

class AddSubmittersOrderToSubmissions < ActiveRecord::Migration[7.0]
  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def change
    add_column :submissions, :submitters_order, :string

    MigrationSubmission.where(submitters_order: nil).update_all(submitters_order: 'random')

    change_column_null :submissions, :submitters_order, false
  end
end
