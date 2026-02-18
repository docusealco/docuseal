# frozen_string_literal: true

class SendFormCompletedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])
    webhook_url = WebhookUrl.find(params['webhook_url_id'])

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('form.completed')

    Submissions::EnsureResultGenerated.call(submitter)

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    # Build the payload with submission events for granular audit tracking
    webhook_data = Submitters::SerializeForWebhook.call(submitter)

    # Add submission events for CareerPlug ATS integration
    webhook_data['submission_events'] = serialize_submission_events(submitter.submission)

    resp = SendWebhookRequest.call(webhook_url, event_type: 'form.completed',
                                                data: webhook_data)

    return unless WebhookRetryLogic.should_retry?(response: resp, attempt: attempt, record: submitter)

    SendFormCompletedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                    **params,
                                                    'attempt' => attempt + 1,
                                                    'last_status' => resp&.status.to_i
                                                  })
  end

  private

  # Serialize submission events for webhook payload
  # Returns array of event hashes with field-level change tracking
  def serialize_submission_events(submission)
    submission.submission_events.order(:event_timestamp).map do |event|
      {
        id: event.id,
        event_type: event.event_type,
        event_timestamp: event.event_timestamp.iso8601,
        user_id: event.user_id,
        data: event.data
      }
    end
  end
end
