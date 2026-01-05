# frozen_string_literal: true

module Submissions
  module EnsureAuditGenerated
    WAIT_FOR_RETRY = 2.seconds
    CHECK_EVENT_INTERVAL = 1.second
    CHECK_COMPLETE_TIMEOUT = 90.seconds
    KEY_PREFIX = 'audit_trail'

    WaitForCompleteTimeout = Class.new(StandardError)
    NotCompletedYet = Class.new(StandardError)

    module_function

    def call(submission)
      return nil unless submission

      raise NotCompletedYet unless submission.submitters.all?(&:completed_at?)

      total_wait_time ||= 0
      key = [KEY_PREFIX, submission.id].join(':')

      if ApplicationRecord.uncached { LockEvent.exists?(key:, event_name: :complete) }
        return submission.audit_trail_attachment
      end

      events = ApplicationRecord.uncached { LockEvent.where(key:).order(:id).to_a }

      if events.present? && events.last.event_name.in?(%w[start retry])
        wait_for_complete_or_fail(submission)
      else
        LockEvent.create!(key:, event_name: events.present? ? :retry : :start)

        result = Submissions::GenerateAuditTrail.call(submission)

        LockEvent.create!(key:, event_name: :complete)

        result
      end
    rescue ActiveRecord::RecordNotUnique
      sleep WAIT_FOR_RETRY

      total_wait_time += WAIT_FOR_RETRY

      total_wait_time > CHECK_COMPLETE_TIMEOUT ? raise : retry
    rescue StandardError => e
      Rollbar.error(e) if defined?(Rollbar)
      Rails.logger.error(e)

      LockEvent.create!(key:, event_name: :fail)

      raise
    end

    def wait_for_complete_or_fail(submission)
      total_wait_time = 0

      loop do
        sleep CHECK_EVENT_INTERVAL
        total_wait_time += CHECK_EVENT_INTERVAL

        last_event =
          ApplicationRecord.uncached do
            LockEvent.where(key: [KEY_PREFIX, submission.id].join(':')).order(:id).last
          end

        if last_event.event_name.in?(%w[complete fail])
          break ApplicationRecord.uncached do
            ActiveStorage::Attachment.find_by(record: submission, name: 'audit_trail')
          end
        end

        raise WaitForCompleteTimeout if total_wait_time > CHECK_COMPLETE_TIMEOUT
      end
    end
  end
end
