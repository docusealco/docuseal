# frozen_string_literal: true

class CreateEmailMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :email_messages do |t|
      t.string :uuid, null: false, index: true
      t.references :author, null: false, foreign_key: { to_table: :users }, index: false
      t.references :account, null: false, foreign_key: true, index: true
      t.text :subject, null: false
      t.text :body, null: false
      t.string :sha1, null: false, index: true

      t.timestamps
    end
  end
end
