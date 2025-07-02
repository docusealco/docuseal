class CreateExportLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :export_locations do |t|
      t.string :name, null: false
      t.boolean :default_location, null: false, default: false
      t.string :authorization_token
      t.string :api_base_url, null: false
      # t.string extra_params, null: false, default: '{}'
      t.string :templates_endpoint
      # t.string other_export_type_endpoints_maybe_one_day
      t.timestamps
    end
  end
end
