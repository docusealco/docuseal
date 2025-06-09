# frozen_string_literal: true

# == Schema Information
#
# Table name: search_entries
#
#  id          :bigint           not null, primary key
#  ngram       :tsvector
#  record_type :string           not null
#  tsvector    :tsvector         not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  record_id   :bigint           not null
#
# Indexes
#
#  index_search_entries_on_account_id_ngram_submission     (account_id,ngram) WHERE ((record_type)::text = 'Submission'::text) USING gin
#  index_search_entries_on_account_id_ngram_submitter      (account_id,ngram) WHERE ((record_type)::text = 'Submitter'::text) USING gin
#  index_search_entries_on_account_id_ngram_template       (account_id,ngram) WHERE ((record_type)::text = 'Template'::text) USING gin
#  index_search_entries_on_account_id_tsvector_submission  (account_id,tsvector) WHERE ((record_type)::text = 'Submission'::text) USING gin
#  index_search_entries_on_account_id_tsvector_submitter   (account_id,tsvector) WHERE ((record_type)::text = 'Submitter'::text) USING gin
#  index_search_entries_on_account_id_tsvector_template    (account_id,tsvector) WHERE ((record_type)::text = 'Template'::text) USING gin
#  index_search_entries_on_record_id_and_record_type       (record_id,record_type) UNIQUE
#
class SearchEntry < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :account
end
