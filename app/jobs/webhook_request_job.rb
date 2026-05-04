# frozen_string_literal: true

module WebhookRequestJob
  extend ActiveSupport::Concern

  DEFAULT_MAX_ATTEMPTS = 10

  included do
    include Sidekiq::Job

    sidekiq_options queue: :webhooks
  end

  def perform_webhook_request(params, record_key:, record_class:, event_type:)
    record = record_class.find_by(id: params[record_key])

    return unless record

    webhook_url = WebhookUrl.find_by(id: params['webhook_url_id'])

    return unless webhook_url

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?(event_type)

    resp = SendWebhookRequest.call(webhook_url, event_type:,
                                                event_uuid: params['event_uuid'],
                                                record:,
                                                attempt:,
                                                data: yield(record))

    retry_webhook_request(resp, record, params, attempt)
  end

  private

  def retry_webhook_request(resp, record, params, attempt)
    return unless retry_webhook_request?(resp, record, attempt)

    self.class.perform_in((2**attempt).minutes, {
                            **params,
                            'attempt' => attempt + 1,
                            'last_status' => resp&.status.to_i
                          })
  end

  def retry_webhook_request?(resp, record, attempt)
    (resp.nil? || resp.status.to_i >= 400) &&
      attempt <= max_attempts &&
      (!Docuseal.multitenant? || record.account.account_configs.exists?(key: :plan))
  end

  def max_attempts
    self.class.const_defined?(:MAX_ATTEMPTS, false) ? self.class::MAX_ATTEMPTS : DEFAULT_MAX_ATTEMPTS
  end
end
