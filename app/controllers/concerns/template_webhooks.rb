# frozen_string_literal: true

module TemplateWebhooks
  def enqueue_template_created_webhooks(template)
    WebhookUrls.for_template(template, 'template.created').each do |webhook_url|
      SendTemplateCreatedWebhookRequestJob.perform_async('template_id' => template.id,
                                                         'webhook_url_id' => webhook_url.id)
    end
  end

  def enqueue_template_updated_webhooks(template)
    WebhookUrls.for_template(template, 'template.updated').each do |webhook_url|
      SendTemplateUpdatedWebhookRequestJob.perform_async('template_id' => template.id,
                                                         'webhook_url_id' => webhook_url.id)
    end
  end

  def enqueue_template_preferences_updated_webhooks(template)
    WebhookUrls.for_template(template, 'template.preferences_updated').each do |webhook_url|
      SendTemplatePreferencesUpdatedWebhookRequestJob.perform_async('template_id' => template.id,
                                                                    'webhook_url_id' => webhook_url.id)
    end
  end
end
