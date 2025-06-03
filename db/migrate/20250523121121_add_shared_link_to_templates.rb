# frozen_string_literal: true

class AddSharedLinkToTemplates < ActiveRecord::Migration[8.0]
  disable_ddl_transaction

  class MigrationTemplate < ActiveRecord::Base
    self.table_name = 'templates'
  end

  def up
    add_column :templates, :shared_link, :boolean, if_not_exists: true

    MigrationTemplate.where(shared_link: nil).in_batches.update_all(shared_link: true)

    change_column_default :templates, :shared_link, from: nil, to: false
    change_column_null :templates, :shared_link, false
  end

  def down
    remove_column :templates, :shared_link
  end
end
