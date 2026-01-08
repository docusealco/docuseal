# frozen_string_literal: true

# Migration 1: Add institution_id to account_access
# Part of Winston's 4-layer data isolation foundation
class AddInstitutionIdToAccountAccess < ActiveRecord::Migration[7.0]
  def change
    # Step 1: Add nullable institution_id column
    add_reference :account_accesses, :institution, foreign_key: { to_table: :institutions }, index: true, null: true

    # Step 2: Add foreign key constraint
    # Note: We'll add the constraint after backfilling data in a separate migration
    # to avoid locking issues on large tables

    # Step 3: Add unique index for [user_id, institution_id] to prevent duplicate roles
    # This will be added after data backfill when institution_id is non-nullable
  end
end