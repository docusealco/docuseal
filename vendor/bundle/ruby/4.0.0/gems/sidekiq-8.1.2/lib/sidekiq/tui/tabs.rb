require_relative "tabs/home"
require_relative "tabs/busy"
require_relative "tabs/queues"
require_relative "tabs/scheduled"
require_relative "tabs/retries"
require_relative "tabs/dead"
require_relative "tabs/metrics"

module Sidekiq
  class TUI
    module Tabs
      All = Set.new([Home, Busy, Queues, Scheduled, Retries, Dead, Metrics])
    end
  end
end
