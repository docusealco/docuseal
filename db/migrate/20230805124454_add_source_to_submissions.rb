# frozen_string_literal: true

class AddSourceToSubmissions < ActiveRecord::Migration[7.0]
  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def up
    add_column :submissions, :source, :string

    MigrationSubmission.where(source: nil).update_all(source: :invite)

    change_column_null :submissions, :source, false
  end

  def down
    drop_column :submissions, :source
  end
end
