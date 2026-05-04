# frozen_string_literal: true

class SendSubmissionCompletedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'submission.completed',
                  record_class: Submission,
                  record_id_param: 'submission_id',
                  data: Submissions::SerializeForApi
end
