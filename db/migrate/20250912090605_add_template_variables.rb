# frozen_string_literal: true

class AddTemplateVariables < ActiveRecord::Migration[8.0]
  def change
    add_column :templates, :variables_schema, :text
    add_column :submissions, :variables_schema, :text
    add_column :submissions, :variables, :text
  end
end
