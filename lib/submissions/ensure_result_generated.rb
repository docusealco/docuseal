# frozen_string_literal: true

module Submissions
  module EnsureResultGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds

    WaitForCompleteTimeout = Class.new(StandardError)

    module_function

    def call(submitter)
      return [] unless submitter
      return submitter.documents if ApplicationRecord.uncached { submitter.document_generation_events.complete.exists? }

      events =
        ApplicationRecord.uncached do
          DocumentGenerationEvent.where(submitter:).order(:created_at).to_a
        end

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submitter)
      else
        submitter.document_generation_events.create!(event_name: events.present? ? :retry : :start)

        documents = GenerateResultAttachments.call(submitter)

        submitter.document_generation_events.create!(event_name: :complete)

        documents
      end
    rescue ActiveRecord::RecordNotUnique
      sleep WAIT_FOR_RETRY

      retry
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      Rails.logger.error(e)

      submitter.document_generation_events.create!(event_name: :fail)

      raise
    end

    def wait_for_complete_or_fail(submitter)
      total_wait_time = 0

      loop do
        sleep CHECK_EVENT_INTERVAL
        total_wait_time += CHECK_EVENT_INTERVAL

        last_event =
          ApplicationRecord.uncached do
            DocumentGenerationEvent.where(submitter:).order(:created_at).last
          end

        break submitter.documents.reload if last_event.event_name.in?(%w[complete fail])

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
