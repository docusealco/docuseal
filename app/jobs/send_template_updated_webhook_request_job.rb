# frozen_string_literal: true

class SendTemplateUpdatedWebhookRequestJob
  include WebhookRequestJob

  def perform(params = {})
    perform_webhook_request(params, record_key: 'template_id', record_class: Template,
                                    event_type: 'template.updated') do |template|
      Templates::SerializeForApi.call(template)
    end
  end
end
