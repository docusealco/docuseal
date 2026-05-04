# frozen_string_literal: true

class SendTemplateCreatedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'template.created',
                  record_class: Template,
                  record_id_param: 'template_id',
                  data: Templates::SerializeForApi
end
