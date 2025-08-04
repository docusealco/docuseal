# frozen_string_literal: true

class CreateSearchEnties < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    return unless adapter_name == 'PostgreSQL'

    create_table :search_entries do |t|
      t.references :record, null: false, polymorphic: true, index: false
      t.bigint :account_id, null: false
      t.tsvector :tsvector, null: false

      t.timestamps
    end

    begin
      enable_extension 'btree_gin'
    rescue StandardError
      nil
    end

    btree_gin_enabled = extension_enabled?('btree_gin')

    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Submitter'",
              name: 'index_search_entries_on_account_id_tsvector_submitter'
    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Submission'",
              name: 'index_search_entries_on_account_id_tsvector_submission'
    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Template'",
              name: 'index_search_entries_on_account_id_tsvector_template'

    add_index :search_entries, %i[record_id record_type], unique: true
  end

  def down
    return unless adapter_name == 'PostgreSQL'

    drop_table :search_entries

    begin
      disable_extension 'btree_gin'
    rescue StandardError
      nil
    end
  end
end
