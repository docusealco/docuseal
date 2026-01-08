# frozen_string_literal: true

# Migration 2: Create institutions table
# Part of Winston's 4-layer data isolation foundation
class CreateInstitutions < ActiveRecord::Migration[7.0]
  def change
    create_table :institutions do |t|
      # Core relationships
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.references :super_admin, null: false, foreign_key: { to_table: :users }

      # Institution details
      t.string :name, null: false
      t.string :registration_number
      t.text :address
      t.string :contact_email
      t.string :contact_phone

      # Settings (JSONB for flexibility)
      t.jsonb :settings, null: false, default: {}

      # Timestamps
      t.timestamps
    end

    # Unique constraints
    add_index :institutions, [:account_id, :registration_number], unique: true, where: 'registration_number IS NOT NULL'
    add_index :institutions, :super_admin_id
  end
end