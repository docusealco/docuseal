# frozen_string_literal: true

require 'benchmark'

class ApplicationJob < ActiveJob::Base
  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  unique :while_executing, on_conflict: :log

  retry_on StandardError, wait: 6.seconds, attempts: 5 unless Docuseal.multitenant?

  def perform(*args)
    receiver_str, _, message = args.shift.rpartition('.')
    time = Benchmark.measure do
      receiver_str.constantize.send(message, *args)
    end
    Rails.logger.info(
      "Finished #{receiver_str}.#{message}(#{args.map(&:to_s).join(', ')}): #{time}"
    )
  end
  add_transaction_tracer :perform, category: :task
end
