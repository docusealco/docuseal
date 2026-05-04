# frozen_string_literal: true

class SendTestWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options retry: 0

  def perform(params = {})
    submitter = Submitter.find_by(id: params['submitter_id'])

    return unless submitter

    webhook_url = WebhookUrl.find_by(id: params['webhook_url_id'])

    return unless webhook_url

    if Docuseal.multitenant?
      uri = begin
        URI(webhook_url.url)
      rescue URI::Error
        Addressable::URI.parse(webhook_url.url).normalize
      end

      if uri.scheme != 'https' || [443, nil].exclude?(uri.port)
        raise SendWebhookRequest::HttpsError, 'Only HTTPS is allowed.'
      end

      if uri.host.in?(SendWebhookRequest::LOCALHOSTS)
        raise SendWebhookRequest::LocalhostError, "Can't send to localhost."
      end
    end

    Faraday.post(webhook_url.url,
                 {
                   event_type: 'form.completed',
                   timestamp: Time.current.iso8601,
                   data: Submitters::SerializeForWebhook.call(submitter)
                 }.to_json,
                 'Content-Type' => 'application/json',
                 'User-Agent' => SendWebhookRequest::USER_AGENT,
                 **webhook_url.secret.to_h)
  end
end
