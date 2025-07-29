# frozen_string_literal: true

class AddSubmissionsEndpointToExportLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :export_locations, :submissions_endpoint, :string
  end
end
