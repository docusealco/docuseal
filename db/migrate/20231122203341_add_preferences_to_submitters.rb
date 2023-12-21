# frozen_string_literal: true

class AddPreferencesToSubmitters < ActiveRecord::Migration[7.0]
  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'
  end

  def change
    add_column :submitters, :preferences, :text

    MigrationSubmitter.where(preferences: nil).update_all(preferences: '{}')

    change_column_null :submitters, :preferences, false
  end
end
