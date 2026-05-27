require_relative "base_tab"
require_relative "set_tab"

module Sidekiq
  class TUI
    module Tabs
      class Retries < BaseTab
        include SetTab

        def set_class = Sidekiq::RetrySet

        def refresh_data
          refresh_data_for_stats
          refresh_data_for_set
        end
      end
    end
  end
end
