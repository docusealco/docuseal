# frozen_string_literal: true

class SendFormViewedWebhookRequestJob < ApplicationJob
  USER_AGENT = 'DocuSeal.co Webhook'

  NotSuccessStatus = Class.new(StandardError)

  def perform(submitter)
    config = Accounts.load_webhook_configs(submitter.submission.account)

    return if config.blank? || config.value.blank?

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    resp = Faraday.post(config.value,
                        {
                          event_type: 'form.viewed',
                          timestamp: Time.current,
                          data: Submitters::SerializeForWebhook.call(submitter)
                        }.to_json,
                        'Content-Type' => 'application/json',
                        'User-Agent' => USER_AGENT)

    if resp.status.to_i >= 400 && (!Docuseal.multitenant? || submitter.account.account_configs.exists?(key: :plan))
      raise NotSuccessStatus, resp.status.to_s
    end
  end
end
