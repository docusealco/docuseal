# frozen_string_literal: true

class SendFormStartedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'form.started',
                  record_class: Submitter,
                  record_id_param: 'submitter_id',
                  data: Submitters::SerializeForWebhook,
                  default_url_options: true
end
