# frozen_string_literal: true

class AddPreferencesToTemplates < ActiveRecord::Migration[7.1]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  def change
    add_column :templates, :preferences, :text

    MigrationTemplate.where(preferences: nil).update_all(preferences: '{}')

    change_column_null :templates, :preferences, false
  end
end
