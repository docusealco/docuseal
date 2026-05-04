# frozen_string_literal: true

class SendSubmissionCompletedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'submission_id', record_class: Submission,
                                    event_type: 'submission.completed') do |submission|
      Submissions::SerializeForApi.call(submission)
    end
  end
end
