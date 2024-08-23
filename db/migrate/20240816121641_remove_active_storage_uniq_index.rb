# frozen_string_literal: true

class RemoveActiveStorageUniqIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :active_storage_attachments, %i[record_type record_id name blob_id],
                 unique: true,
                 name: 'index_active_storage_attachments_uniqueness'

    add_index :active_storage_attachments, %i[record_type record_id name blob_id]
  end
end
