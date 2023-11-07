# frozen_string_literal: true

class SendFormCompletedWebhookRequestJob < ApplicationJob
  USER_AGENT = 'DocuSeal.co Webhook'

  def perform(submitter)
    config = Accounts.load_webhook_configs(submitter.submission.account)

    return if config.blank? || config.value.blank?

    Submissions::EnsureResultGenerated.call(submitter)

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    Faraday.post(config.value,
                 {
                   event_type: 'form.completed',
                   timestamp: Time.current,
                   data: Submitters::SerializeForWebhook.call(submitter)
                 }.to_json,
                 'Content-Type' => 'application/json',
                 'User-Agent' => USER_AGENT)
  end
end
