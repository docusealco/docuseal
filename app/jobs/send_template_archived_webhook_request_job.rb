# frozen_string_literal: true

class SendTemplateArchivedWebhookRequestJob
  include WebhookRequestJob

  webhook_request event_type: 'template.archived',
                  record_class: Template,
                  record_id_param: 'template_id',
                  data: ->(template) { template.as_json(only: %i[id archived_at]) }
end
