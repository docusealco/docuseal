# frozen_string_literal: true

class SendTemplateArchivedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'template_id', record_class: Template,
                                    event_type: 'template.archived') do |template|
      template.as_json(only: %i[id archived_at])
    end
  end
end
