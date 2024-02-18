# frozen_string_literal: true

class AddUuidToActiveStorageBlobs < ActiveRecord::Migration[7.1]
  def change
    add_column :active_storage_blobs, :uuid, :string

    add_index :active_storage_blobs, :uuid, unique: true
  end
end
