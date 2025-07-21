# frozen_string_literal: true

class AddParentFolderIdToTemplateFolders < ActiveRecord::Migration[8.0]
  def change
    add_reference :template_folders, :parent_folder, foreign_key: { to_table: :template_folders }, index: true
  end
end
