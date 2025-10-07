class AddStorageLocationToCompletedDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :completed_documents, :storage_location, :string, default: 'secured'
    add_index :completed_documents, :storage_location
  end
end
