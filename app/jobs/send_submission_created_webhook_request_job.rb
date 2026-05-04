# frozen_string_literal: true

class SendSubmissionCreatedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'submission_id', record_class: Submission,
                                    event_type: 'submission.created') do |submission|
      Submissions::SerializeForApi.call(submission)
    end
  end
end
