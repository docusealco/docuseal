# frozen_string_literal: true

class AddSourceToTemplates < ActiveRecord::Migration[7.0]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  def up
    add_column :templates, :source, :text

    MigrationTemplate.where(source: nil).update_all(source: :native)

    change_column_null :templates, :source, false
  end

  def down
    drop_column :templates, :source
  end
end
