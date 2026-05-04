# frozen_string_literal: true

class SendTemplateUpdatedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'template.updated',
                  record_class: Template,
                  record_id_param: 'template_id',
                  data: Templates::SerializeForApi
end
