# frozen_string_literal: true

module SendWebhookRequest
  USER_AGENT = 'DocuSeal.com Webhook'

  LOCALHOSTS = %w[0.0.0.0 127.0.0.1 localhost].freeze

  HttpsError = Class.new(StandardError)
  LocalhostError = Class.new(StandardError)

  module_function

  def call(webhook_url, event_type:, data:)
    uri = begin
      URI(webhook_url.url)
    rescue URI::Error
      Addressable::URI.parse(webhook_url.url).normalize
    end

    if Docuseal.multitenant?
      raise HttpsError, 'Only HTTPS is allowed.' if uri.scheme != 'https' &&
                                                    !AccountConfig.exists?(key: :allow_http,
                                                                           account_id: webhook_url.account_id)
      raise LocalhostError, "Can't send to localhost." if uri.host.in?(LOCALHOSTS)
    end

    Faraday.post(uri) do |req|
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
