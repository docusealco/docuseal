# frozen_string_literal: true

# Migration 5: Backfill institution data
# Part of Winston's 4-layer data isolation foundation
# This migration backfills existing data and makes institution_id non-nullable
class BackfillInstitutionData < ActiveRecord::Migration[7.0]
  def up
    # For existing installations, we need to:
    # 1. Create default institutions for each account
    # 2. Link existing users to their institutions via account_access
    # 3. Make institution_id non-nullable

    # Note: This is a data migration that should be run carefully in production
    # We'll use raw SQL for performance on large datasets

    execute <<-SQL
      -- Step 1: Create default institutions for accounts that don't have them
      INSERT INTO institutions (
        account_id,
        super_admin_id,
        name,
        registration_number,
        address,
        contact_email,
        contact_phone,
        settings,
        created_at,
        updated_at
      )
      SELECT DISTINCT
        a.id as account_id,
        (
          SELECT u.id
          FROM users u
          WHERE u.account_id = a.id
          AND u.role = 'admin'
          ORDER BY u.created_at
          LIMIT 1
        ) as super_admin_id,
        COALESCE(a.name, 'Default Institution') as name,
        NULL as registration_number,
        NULL as address,
        NULL as contact_email,
        NULL as contact_phone,
        '{}'::jsonb as settings,
        NOW() as created_at,
        NOW() as updated_at
      FROM accounts a
      LEFT JOIN institutions i ON a.id = i.account_id
      WHERE i.id IS NULL;

      -- Step 2: Update account_accesses with institution_id
      UPDATE account_accesses aa
      SET institution_id = i.id
      FROM institutions i
      WHERE aa.account_id = i.account_id;

      -- Step 3: Add default role for existing records
      UPDATE account_accesses
      SET role = 'cohort_super_admin'
      WHERE institution_id IS NOT NULL;

      -- Step 4: Add unique index for [user_id, institution_id]
      -- This will prevent duplicate roles
      CREATE UNIQUE INDEX index_account_accesses_on_user_id_and_institution_id
      ON account_accesses(user_id, institution_id)
      WHERE institution_id IS NOT NULL;
    SQL

    # Step 5: Make institution_id non-nullable
    change_column_null :account_accesses, :institution_id, false

    # Step 6: Add foreign key constraint
    add_foreign_key :account_accesses, :institutions, name: 'fk_account_accesses_to_institutions'
  end

  def down
    # Reverse operations
    remove_foreign_key :account_accesses, name: 'fk_account_accesses_to_institutions'
    change_column_null :account_accesses, :institution_id, true
    remove_index :account_accesses, name: 'index_account_accesses_on_user_id_and_institution_id'

    # Don't delete institutions as they may contain important data
    # Instead, just nullify the institution_id in account_accesses
    execute 'UPDATE account_accesses SET institution_id = NULL'
  end
end