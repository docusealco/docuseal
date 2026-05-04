# frozen_string_literal: true

class SendSubmissionArchivedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'submission.archived',
                  record_class: Submission,
                  record_id_param: 'submission_id',
                  data: ->(submission) { submission.as_json(only: %i[id archived_at]) }
end
