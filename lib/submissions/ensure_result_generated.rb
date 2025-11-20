# frozen_string_literal: true

module Submissions
  module EnsureResultGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds

    WaitForCompleteTimeout = Class.new(StandardError)
    NotCompletedYet = Class.new(StandardError)

    module_function

    def call(submitter)
      return [] unless submitter

      raise NotCompletedYet unless submitter.completed_at?

      key = ['result_attachments', submitter.id].join(':')

      return submitter.documents if ApplicationRecord.uncached { LockEvent.exists?(key:, event_name: :complete) }

      events = ApplicationRecord.uncached { LockEvent.where(key:).order(:id).to_a }

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submitter)
      else
        LockEvent.create!(key:, event_name: events.present? ? :retry : :start)

        documents = GenerateResultAttachments.call(submitter)

        LockEvent.create!(key:, event_name: :complete)

        documents
      end
    rescue ActiveRecord::RecordNotUnique
      sleep WAIT_FOR_RETRY

      retry
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      Rails.logger.error(e)

      LockEvent.create!(key:, event_name: :fail)

      raise
    end

    def wait_for_complete_or_fail(submitter)
      total_wait_time = 0

      loop do
        sleep CHECK_EVENT_INTERVAL
        total_wait_time += CHECK_EVENT_INTERVAL

        last_event =
          ApplicationRecord.uncached do
            LockEvent.where(key: ['result_attachments', submitter.id].join(':')).order(:id).last
          end

        break submitter.documents.reload if last_event.event_name.in?(%w[complete fail])

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
