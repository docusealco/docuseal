# frozen_string_literal: true

module SendWebhookRequest
  USER_AGENT = 'DocuSeal.com Webhook'

  LOCALHOSTS = %w[0.0.0.0 127.0.0.1 localhost].freeze

  MANUAL_ATTEMPT = 99_999
  AUTOMATED_RETRY_RANGE = 1..MANUAL_ATTEMPT - 1

  HttpsError = Class.new(StandardError)
  LocalhostError = Class.new(StandardError)

  module_function

  # rubocop:disable Metrics/AbcSize
  def call(webhook_url, event_uuid:, event_type:, record:, data:, attempt: 0)
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

    webhook_event = create_webhook_event(webhook_url, event_uuid:, event_type:, record:)

    return if AUTOMATED_RETRY_RANGE.cover?(attempt.to_i) && webhook_event&.status == 'success'

    response = Faraday.post(uri) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['User-Agent'] = USER_AGENT
      req.headers.merge!(webhook_url.secret.to_h) if webhook_url.secret.present?

      req.body = {
        event_type: event_type,
        timestamp: webhook_event&.created_at || Time.current,
        data: data
      }.to_json

      req.options.read_timeout = 8
      req.options.open_timeout = 8
    end

    handle_response(webhook_event, response:, attempt:)
  rescue Faraday::SSLError, Faraday::TimeoutError, Faraday::ConnectionFailed => e
    handle_error(webhook_event, attempt:, error_message: e.class.name.split('::').last)
  rescue Faraday::Error => e
    handle_error(webhook_event, attempt:, error_message: e.message&.truncate(100))
  end
  # rubocop:enable Metrics/AbcSize

  def create_webhook_event(webhook_url, event_uuid:, event_type:, record:)
    return if event_uuid.blank?

    WebhookEvent.create_with(
      event_type:,
      record:,
      account_id: webhook_url.account_id,
      status: 'pending'
    ).find_or_create_by!(webhook_url:, uuid: event_uuid)
  end

  def handle_response(webhook_event, response:, attempt:)
    return response unless webhook_event

    is_error = response.status.to_i >= 400

    WebhookAttempt.create!(
      webhook_event:,
      response_body: is_error ? response.body&.truncate(100) : nil,
      response_status_code: response.status,
      attempt:
    )

    webhook_event.update!(status: is_error ? 'error' : 'success')

    response
  rescue StandardError
    raise if Rails.env.local?

    nil
  end

  def handle_error(webhook_event, error_message:, attempt:)
    return unless webhook_event

    WebhookAttempt.create!(
      webhook_event:,
      response_body: error_message,
      response_status_code: 0,
      attempt:
    )

    webhook_event.update!(status: 'error')

    nil
  rescue StandardError
    raise if Rails.env.local?

    nil
  end
end
