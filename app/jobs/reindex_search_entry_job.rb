# frozen_string_literal: true

class ReindexSearchEntryJob
  include Sidekiq::Job

  def perform(params = {})
    entry = SearchEntry.find_or_initialize_by(params.slice('record_type', 'record_id'))

    SearchEntries.reindex_record(entry.record)
  end
end
