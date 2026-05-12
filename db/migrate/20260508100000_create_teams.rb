# frozen_string_literal: true

class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.references :account, null: false, foreign_key: true
      t.string :uuid, null: false
      t.datetime :archived_at

      t.timestamps
    end

    add_index :teams, :uuid, unique: true
    add_index :teams, %i[account_id name], unique: true, where: 'archived_at IS NULL'
  end
end
