# frozen_string_literal: true

class AddPreferencesToSubmissions < ActiveRecord::Migration[7.0]
  class MigrationSubmission < ApplicationRecord
    self.table_name = 'submissions'
  end

  def change
    add_column :submissions, :preferences, :text

    MigrationSubmission.where(preferences: nil).update_all(preferences: '{}')

    change_column_null :submissions, :preferences, false
  end
end
