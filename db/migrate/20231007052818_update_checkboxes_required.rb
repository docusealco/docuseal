# frozen_string_literal: true

class UpdateCheckboxesRequired < ActiveRecord::Migration[7.0]
  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  def up
    MigrationTemplate.find_each do |template|
      fields = JSON.parse(template.fields)

      fields.each do |field|
        field['required'] = false if field['type'] == 'checkbox'
      end

      template.update_columns(fields: fields.to_json) if JSON.parse(template.fields) != fields
    end
  end

  def down
    nil
  end
end
