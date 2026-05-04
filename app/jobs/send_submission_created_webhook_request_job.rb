# frozen_string_literal: true

class SendSubmissionCreatedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'submission.created',
                  record_class: Submission,
                  record_id_param: 'submission_id',
                  data: Submissions::SerializeForApi
end
