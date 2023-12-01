class AddValuesToTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :templates, :values, :text
  end
end
