# frozen_string_literal: true

# Migration 4: Update account_access roles
# Part of Winston's 4-layer data isolation foundation
class UpdateAccountAccessRoles < ActiveRecord::Migration[7.0]
  def up
    # Add new roles to account_access
    # First, let's check if role column exists and what type it is
    # Based on existing schema, we need to extend the enum

    # Since account_access doesn't have a role column in the current schema,
    # we need to add it first
    add_column :account_accesses, :role, :string, null: false, default: 'member'

    # Add index on role for performance
    add_index :account_accesses, :role
  end

  def down
    remove_index :account_accesses, :role
    remove_column :account_accesses, :role
  end
end