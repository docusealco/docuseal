# frozen_string_literal: true

class SendFormViewedWebhookRequestJob < ApplicationJob
  USER_AGENT = 'DocuSeal.co Webhook'

  def perform(submitter)
    config = submitter.submission.account.encrypted_configs.find_by(key: EncryptedConfig::WEBHOOK_URL_KEY)

    return if config.blank? || config.value.blank?

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    Faraday.post(config.value,
                 {
                   event_type: 'form.viewed',
                   timestamp: Time.current.iso8601,
                   data: Submitters::SerializeForWebhook.call(submitter)
                 }.to_json,
                 'Content-Type' => 'application/json',
                 'User-Agent' => USER_AGENT)
  end
end
