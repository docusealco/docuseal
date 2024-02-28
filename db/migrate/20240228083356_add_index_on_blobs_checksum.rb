# frozen_string_literal: true

class AddIndexOnBlobsChecksum < ActiveRecord::Migration[7.1]
  def change
    add_index :active_storage_blobs, :checksum
  end
end
