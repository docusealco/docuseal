# frozen_string_literal: true

class SendSubmissionCompletedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  def perform(params = {})
    submission = Submission.find(params['submission_id'])
    webhook_url = WebhookUrl.find(params['webhook_url_id'])

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('submission.completed')

    resp = SendWebhookRequest.call(webhook_url, event_type: 'submission.completed',
                                                data: Submissions::SerializeForApi.call(submission))

    return unless WebhookRetryLogic.should_retry?(response: resp, attempt: attempt, record: submission)

    SendSubmissionCompletedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                          **params,
                                                          'attempt' => attempt + 1,
                                                          'last_status' => resp&.status.to_i
                                                        })
  end
end
