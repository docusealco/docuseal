class AddConfirmationToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :confirmation_token, :string, unique: true
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string, unique: true
  end
end
