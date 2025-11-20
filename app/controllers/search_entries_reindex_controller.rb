# frozen_string_literal: true

class SearchEntriesReindexController < ApplicationController
  def create
    authorize!(:manage, EncryptedConfig)

    ReindexAllSearchEntriesJob.perform_async

    AccountConfig.find_or_initialize_by(account_id: Account.minimum(:id), key: :fulltext_search)
                 .update!(value: true)

    Docuseal.instance_variable_set(:@fulltext_search, nil)

    redirect_back(fallback_location: settings_account_path,
                  notice: "Started building search index. Visit #{root_url}jobs/busy to check progress.")
  end
end
