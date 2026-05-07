# frozen_string_literal: true

ActiveSupport.on_load(:sidekiq_config) do
  ProcessSubmitterRemindersJob.perform_in(1.minute)
end
