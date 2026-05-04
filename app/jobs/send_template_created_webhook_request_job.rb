# frozen_string_literal: true

class SendTemplateCreatedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'template_id', record_class: Template,
                                    event_type: 'template.created') do |template|
      Templates::SerializeForApi.call(template)
    end
  end
end
