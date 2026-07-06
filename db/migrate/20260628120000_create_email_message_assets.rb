# frozen_string_literal: true

class CreateEmailMessageAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :email_message_assets do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.text :data, null: false
      t.string :sha1, null: false
      t.timestamps
    end

    add_index :email_message_assets, %i[account_id sha1], unique: true
  end
end
