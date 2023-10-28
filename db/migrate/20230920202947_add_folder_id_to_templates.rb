# frozen_string_literal: true

class AddFolderIdToTemplates < ActiveRecord::Migration[7.0]
  class MigrationTemplateFolder < ApplicationRecord
    self.table_name = 'template_folders'
  end

  class MigrationAccount < ApplicationRecord
    self.table_name = 'accounts'
  end

  class MigrationTemplate < ApplicationRecord
    self.table_name = 'templates'
  end

  class MigrationUser < ApplicationRecord
    self.table_name = 'users'
  end

  def up
    add_reference :templates, :folder, foreign_key: { to_table: :template_folders }, index: true, null: true

    MigrationAccount.pluck(:id).each do |account_id|
      author_id = MigrationUser.where(account_id:).minimum(:id)

      next if author_id.blank?

      folder = MigrationTemplateFolder.create_with(author_id:)
                                      .find_or_create_by(name: 'Default', account_id:)

      MigrationTemplate.where(account_id:).update_all(folder_id: folder.id)
    end

    change_column_null :templates, :folder_id, false
  end

  def down
    remove_column :templates, :folder_id
  end
end
