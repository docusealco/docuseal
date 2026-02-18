# frozen_string_literal: true

# Shared logic for determining if webhook requests should be retried
# Used across all Send*WebhookRequestJob classes
module WebhookRetryLogic
  module_function

  MAX_ATTEMPTS = 10

  # Determines if a failed webhook request should be retried
  #
  # @param response [HTTP::Response, nil] The HTTP response from the webhook request
  # @param attempt [Integer] Current retry attempt number
  # @param record [Template, Submission, Submitter] The record triggering the webhook
  # @return [Boolean] true if the webhook should be retried
  def should_retry?(response:, attempt:, record:)
    return false unless response.nil? || response.status.to_i >= 400
    return false if attempt > MAX_ATTEMPTS
    return true unless Docuseal.multitenant?

    eligible_for_retries?(record)
  end

  # Checks if a record is eligible for webhook retries in multitenant mode
  # @param record [Template, Submission, Submitter] The record to check
  # @return [Boolean] true if eligible for retries
  def eligible_for_retries?(record)
    case record
    when Template
      record.partnership_id.present? || record.account&.account_configs&.exists?(key: :plan)
    when Submission, Submitter
      record.account.account_configs.exists?(key: :plan)
    else
      false
    end
  end
end
