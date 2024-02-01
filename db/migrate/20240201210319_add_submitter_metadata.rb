# frozen_string_literal: true

class AddSubmitterMetadata < ActiveRecord::Migration[7.1]
  class MigrationSubmitter < ApplicationRecord
    self.table_name = 'submitters'
  end

  def change
    add_column :submitters, :metadata, :text

    MigrationSubmitter.where(metadata: nil).update_all(metadata: '{}')

    change_column_null :submitters, :metadata, false
  end
end
