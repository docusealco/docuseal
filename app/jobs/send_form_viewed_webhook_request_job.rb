# frozen_string_literal: true

class SendFormViewedWebhookRequestJob < ApplicationJob
  USER_AGENT = 'DocuSeal.co Webhook'

  def perform(submitter)
    config = Accounts.load_webhook_configs(submitter.submission.account)

    return if config.blank? || config.value.blank?

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    Faraday.post(config.value,
                 {
                   event_type: 'form.viewed',
                   timestamp: Time.current,
                   data: Submitters::SerializeForWebhook.call(submitter)
                 }.to_json,
                 'Content-Type' => 'application/json',
                 'User-Agent' => USER_AGENT)
  end
end
