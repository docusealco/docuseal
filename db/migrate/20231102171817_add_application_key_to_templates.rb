# frozen_string_literal: true

class AddApplicationKeyToTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :templates, :application_key, :string
  end
end
