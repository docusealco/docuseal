# frozen_string_literal: true

class RenameApplicationKeyToExternalId < ActiveRecord::Migration[7.1]
  def change
    rename_column :templates, :application_key, :external_id
    rename_column :submitters, :application_key, :external_id
  end
end
