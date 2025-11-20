# frozen_string_literal: true

class ReindexAllSearchEntriesJob
  include Sidekiq::Job

  def perform
    SearchEntries.reindex_all
  end
end
