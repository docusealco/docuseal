# frozen_string_literal: true

class SendFormViewedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'form.viewed',
                  record_class: Submitter,
                  record_id_param: 'submitter_id',
                  data: Submitters::SerializeForWebhook,
                  default_url_options: true
end
