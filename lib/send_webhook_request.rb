# frozen_string_literal: true

module SendWebhookRequest
  USER_AGENT = 'DocuSeal.com Webhook'

  module_function

  def call(webhook_url, event_type:, data:)
    Faraday.post(webhook_url.url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['User-Agent'] = USER_AGENT
      req.headers.merge!(webhook_url.secret.to_h) if webhook_url.secret.present?

      req.body = {
        event_type: event_type,
        timestamp: Time.current,
        data: data
      }.to_json

      req.options.read_timeout = 8
      req.options.open_timeout = 8
    end
  rescue Faraday::Error
    nil
  end
end
