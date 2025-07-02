class AddAuthParamsToExportLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :export_locations, :extra_params, :jsonb, null: false, default: {}
  end
end
