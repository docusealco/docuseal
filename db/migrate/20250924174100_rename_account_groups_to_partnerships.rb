class RenameAccountGroupsToPartnerships < ActiveRecord::Migration[8.0]
  def change
    # Rename the table
    rename_table :account_groups, :partnerships

    # Rename the foreign key columns in other tables
    rename_column :templates, :account_group_id, :partnership_id
    rename_column :template_folders, :account_group_id, :partnership_id
    rename_column :export_locations, :global_account_group_id, :global_partnership_id

    # Remove partnership relationships since both users and accounts use API context now
    remove_column :users, :account_group_id, :bigint
    remove_column :accounts, :account_group_id, :bigint

    # Rename the external ID column to match new naming
    rename_column :partnerships, :external_account_group_id, :external_partnership_id
  end
end
