# frozen_string_literal: true

class SendTemplatePreferencesUpdatedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  def perform(params = {})
    template = Template.find(params['template_id'])
    webhook_url = WebhookUrl.find(params['webhook_url_id'])

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('template.preferences_updated')

    data = {
      id: template.id,
      external_account_id: template.account&.external_account_id,
      external_partnership_id: template.partnership&.external_partnership_id,
      external_id: template.external_id,
      application_key: template.application_key,
      submitters_order: template.preferences['submitters_order']
    }

    resp = SendWebhookRequest.call(webhook_url, event_type: 'template.preferences_updated', data:)

    return unless WebhookRetryLogic.should_retry?(response: resp, attempt: attempt, record: template)

    SendTemplatePreferencesUpdatedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                                 'template_id' => template.id,
                                                                 'webhook_url_id' => webhook_url.id,
                                                                 'attempt' => attempt + 1,
                                                                 'last_status' => resp&.status.to_i
                                                               })
  end
end
