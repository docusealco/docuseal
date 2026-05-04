# frozen_string_literal: true

class SendFormDeclinedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'form.declined',
                  record_class: Submitter,
                  record_id_param: 'submitter_id',
                  data: Submitters::SerializeForWebhook,
                  default_url_options: true
end
