class AddExternalIdsToAccountsAndUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :external_account_id, :integer
    add_column :users, :external_user_id, :integer
    
    add_index :accounts, :external_account_id, unique: true
    add_index :users, :external_user_id, unique: true
  end
end
