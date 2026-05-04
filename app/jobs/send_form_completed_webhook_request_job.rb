# frozen_string_literal: true

class SendFormCompletedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'form.completed',
                  record_class: Submitter,
                  record_id_param: 'submitter_id',
                  data: Submitters::SerializeForWebhook,
                  max_attempts: 12,
                  ensure_result_generated: true,
                  default_url_options: true
end
