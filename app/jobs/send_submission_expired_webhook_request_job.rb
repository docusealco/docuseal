# frozen_string_literal: true

class SendSubmissionExpiredWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'submission.expired',
                  record_class: Submission,
                  record_id_param: 'submission_id',
                  data: Submissions::SerializeForApi
end
