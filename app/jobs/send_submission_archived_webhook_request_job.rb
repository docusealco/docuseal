# frozen_string_literal: true

class SendSubmissionArchivedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'submission_id', record_class: Submission,
                                    event_type: 'submission.archived') do |submission|
      submission.as_json(only: %i[id archived_at])
    end
  end
end
