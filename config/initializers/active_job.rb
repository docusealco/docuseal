# frozen_string_literal: true

ActiveSupport.on_load(:active_job) do
  ActiveJob::LogSubscriber.class_eval do
    def args_info(_job)
      ''
    end
  end
end
