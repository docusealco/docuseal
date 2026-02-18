# frozen_string_literal: true

class SendFormStartedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])
    webhook_url = WebhookUrl.find(params['webhook_url_id'])

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('form.started')

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    resp = SendWebhookRequest.call(webhook_url, event_type: 'form.started',
                                                data: Submitters::SerializeForWebhook.call(submitter))

    return unless WebhookRetryLogic.should_retry?(response: resp, attempt: attempt, record: submitter)

    SendFormStartedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                  'submitter_id' => submitter.id,
                                                  'webhook_url_id' => webhook_url.id,
                                                  'attempt' => attempt + 1,
                                                  'last_status' => resp&.status.to_i
                                                })
  end
end
