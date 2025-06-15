# frozen_string_literal: true

class CreateSearchEnties < ActiveRecord::Migration[8.0]
  def up
    return unless adapter_name == 'PostgreSQL'

    enable_extension 'btree_gin'

    create_table :search_entries do |t|
      t.references :record, null: false, polymorphic: true, index: false
      t.bigint :account_id, null: false
      t.tsvector :tsvector, null: false

      t.timestamps
    end

    add_index :search_entries, %i[account_id tsvector], using: :gin, where: "record_type = 'Submitter'",
                                                        name: 'index_search_entries_on_account_id_tsvector_submitter'
    add_index :search_entries, %i[account_id tsvector], using: :gin, where: "record_type = 'Submission'",
                                                        name: 'index_search_entries_on_account_id_tsvector_submission'
    add_index :search_entries, %i[account_id tsvector], using: :gin, where: "record_type = 'Template'",
                                                        name: 'index_search_entries_on_account_id_tsvector_template'
    add_index :search_entries, %i[record_id record_type], unique: true
  end

  def down
    return unless adapter_name == 'PostgreSQL'

    drop_table :search_entries

    disable_extension 'btree_gin'
  end
end
