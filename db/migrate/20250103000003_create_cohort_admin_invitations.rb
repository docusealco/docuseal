# frozen_string_literal: true

# Migration 3: Create cohort_admin_invitations table
# Part of Winston's 4-layer data isolation foundation
class CreateCohortAdminInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_admin_invitations do |t|
      # Core relationships
      t.references :institution, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      # Invitation details
      t.string :email, null: false
      t.string :hashed_token, null: false  # SHA-256 hash
      t.string :token_preview, null: false # First 8 chars + '...'
      t.string :role, null: false          # cohort_admin or cohort_super_admin

      # Timestamps
      t.datetime :sent_at
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    # Indexes for performance
    add_index :cohort_admin_invitations, :institution_id
    add_index :cohort_admin_invitations, :email
    add_index :cohort_admin_invitations, :expires_at
    add_index :cohort_admin_invitations, :hashed_token, unique: true
  end
end