# frozen_string_literal: true

ActiveSupport.on_load(:sidekiq_config) do
  require 'sidekiq/api'

  Sidekiq::ScheduledSet.new
    .select { |j| j.klass == 'ProcessSubmitterRemindersJob' }
    .each(&:delete)

  ProcessSubmitterRemindersJob.perform_in(1.minute)
end
