# frozen_string_literal: true

module Submissions
  module EnsureCombinedGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds
    KEY_PREFIX = 'combined_document'

    WaitForCompleteTimeout = Class.new(StandardError)
    NotCompletedYet = Class.new(StandardError)

    module_function

    def call(submitter)
      return nil unless submitter

      raise NotCompletedYet unless submitter.completed_at?

      key = [KEY_PREFIX, submitter.id].join(':')

      if ApplicationRecord.uncached { LockEvent.exists?(key:, event_name: :complete) }
        return submitter.submission.combined_document_attachment
      end

      events = ApplicationRecord.uncached { LockEvent.where(key:).order(:id).to_a }

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submitter)
      else
        LockEvent.create!(key:, event_name: events.present? ? :retry : :start)

        result = Submissions::GenerateCombinedAttachment.call(submitter)

        LockEvent.create!(key:, event_name: :complete)

        result
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
            LockEvent.where(key: [KEY_PREFIX, submitter.id].join(':')).order(:id).last
          end

        if last_event.event_name.in?(%w[complete fail])
          break ApplicationRecord.uncached do
            ActiveStorage::Attachment.find_by(record: submitter.submission, name: 'combined_document')
          end
        end

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
