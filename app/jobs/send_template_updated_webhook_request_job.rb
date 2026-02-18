# frozen_string_literal: true

class SendTemplateUpdatedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  MAX_ATTEMPTS = 10

  def perform(params = {})
    template = Template.find(params['template_id'])
    webhook_url = WebhookUrl.find(params['webhook_url_id'])

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('template.updated')

    resp = SendWebhookRequest.call(webhook_url, event_type: 'template.updated',
                                                data: Templates::SerializeForApi.call(template))

    return unless WebhookRetryLogic.should_retry?(response: resp, attempt: attempt, record: template)

    SendTemplateUpdatedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                      'template_id' => template.id,
                                                      'webhook_url_id' => webhook_url.id,
                                                      'attempt' => attempt + 1,
                                                      'last_status' => resp&.status.to_i
                                                    })
  end
end
