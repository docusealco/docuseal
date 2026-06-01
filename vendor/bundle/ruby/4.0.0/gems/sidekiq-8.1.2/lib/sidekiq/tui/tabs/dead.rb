require_relative "base_tab"
require_relative "set_tab"

module Sidekiq
  class TUI
    module Tabs
      class Dead < BaseTab
        include SetTab

        def set_class = Sidekiq::DeadSet

        def refresh_data
          refresh_data_for_stats
          refresh_data_for_set
        end
      end
    end
  end
end
