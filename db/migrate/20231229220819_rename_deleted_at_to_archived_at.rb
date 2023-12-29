# frozen_string_literal: true

class RenameDeletedAtToArchivedAt < ActiveRecord::Migration[7.1]
  def change
    rename_column :templates, :deleted_at, :archived_at
    rename_column :submissions, :deleted_at, :archived_at
    rename_column :users, :deleted_at, :archived_at
    rename_column :template_folders, :deleted_at, :archived_at
  end
end
