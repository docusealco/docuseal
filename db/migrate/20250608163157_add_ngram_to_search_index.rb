# frozen_string_literal: true

class AddNgramToSearchIndex < ActiveRecord::Migration[8.0]
  def change
    return unless adapter_name == 'PostgreSQL'

    btree_gin_enabled = extension_enabled?('btree_gin')

    add_column :search_entries, :ngram, :tsvector

    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Submitter'",
              name: 'index_search_entries_on_account_id_ngram_submitter'
    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Submission'",
              name: 'index_search_entries_on_account_id_ngram_submission'
    add_index :search_entries, btree_gin_enabled ? %i[account_id tsvector] : :tsvector,
              using: :gin, where: "record_type = 'Template'",
              name: 'index_search_entries_on_account_id_ngram_template'
  end
end
