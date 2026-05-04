# frozen_string_literal: true

module WebhookRequestJob
  def self.included(base)
    base.include Sidekiq::Job
    base.extend ClassMethods
    base.sidekiq_options queue: :webhooks
  end

  module ClassMethods
    attr_reader :webhook_request_config

    def webhook_request(event_type:, record_class:, record_id_param:, data:, max_attempts: 10,
                        ensure_result_generated: false, default_url_options: false)
      @webhook_request_config = {
        event_type:,
        record_class:,
        record_id_param:,
        data:,
        max_attempts:,
        ensure_result_generated:,
        default_url_options:
      }.freeze
    end
  end

  def perform(params = {})
    config = self.class.webhook_request_config
    record = config[:record_class].find_by(id: params[config[:record_id_param]])

    return unless record

    webhook_url = WebhookUrl.find_by(id: params['webhook_url_id'])

    return unless webhook_url

    attempt = params['attempt'].to_i
    event_type = config[:event_type]

    return if webhook_url.url.blank? || webhook_url.events.exclude?(event_type)

    prepare_record(record, config)

    response = SendWebhookRequest.call(webhook_url, event_type:,
                                                    event_uuid: params['event_uuid'],
                                                    record:,
                                                    attempt:,
                                                    data: config[:data].call(record))

    enqueue_retry(params, record, response, attempt, config)
  end

  private

  def prepare_record(record, config)
    Submissions::EnsureResultGenerated.call(record) if config[:ensure_result_generated]
    ActiveStorage::Current.url_options = Docuseal.default_url_options if config[:default_url_options]
  end

  def enqueue_retry(params, record, response, attempt, config)
    return unless retry_webhook_request?(record, response, attempt, config)

    self.class.perform_in((2**attempt).minutes, {
                            **params,
                            'attempt' => attempt + 1,
                            'last_status' => response&.status.to_i
                          })
  end

  def retry_webhook_request?(record, response, attempt, config)
    (response.nil? || response.status.to_i >= 400) && attempt <= config[:max_attempts] &&
      (!Docuseal.multitenant? || record.account.account_configs.exists?(key: :plan))
  end
end
