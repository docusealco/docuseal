# frozen_string_literal: true

# Migration: Create Feature Flags Table
# Purpose: Enable/disable FloDoc functionality without code changes
# Risk: LOW - Simple table with no foreign keys
class CreateFeatureFlags < ActiveRecord::Migration[7.0]
  def change
    create_table :feature_flags do |t|
      t.string :name, null: false, index: { unique: true }
      t.boolean :enabled, default: false, null: false
      t.text :description
      t.timestamps
    end

    # Seed default feature flags
    reversible do |dir|
      dir.up do
        FeatureFlag.create!([
          { name: 'flodoc_cohorts', enabled: true, description: '3-portal cohort management system' },
          { name: 'flodoc_portals', enabled: true, description: 'Student and Sponsor portals' }
        ])
      end
    end
  end
end
