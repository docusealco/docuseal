class AddExternalDataFieldsToTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :templates, :external_data_fields, :string
  end
end
