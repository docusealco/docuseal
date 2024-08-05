# frozen_string_literal: true

class SendFormCompletedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  USER_AGENT = 'DocuSeal.co Webhook'

  MAX_ATTEMPTS = 10

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    attempt = params['attempt'].to_i

    url, secret = load_url_and_secret(submitter, params)

    return if url.blank?

    Submissions::EnsureResultGenerated.call(submitter)

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    resp = begin
      Faraday.post(url,
                   {
                     event_type: 'form.completed',
                     timestamp: Time.current,
                     data: Submitters::SerializeForWebhook.call(submitter)
                   }.to_json,
                   **secret.to_h,
                   'Content-Type' => 'application/json',
                   'User-Agent' => USER_AGENT)
    rescue Faraday::Error
      nil
    end

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || submitter.account.account_configs.exists?(key: :plan))
      SendFormCompletedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                      **params,
                                                      'attempt' => attempt + 1,
                                                      'last_status' => resp&.status.to_i
                                                    })
    end
  end

  def load_url_and_secret(submitter, params)
    if params['encrypted_config_id']
      config = EncryptedConfig.find(params['encrypted_config_id'])

      url = config.value

      return if url.blank?

      preferences = Accounts.load_webhook_preferences(submitter.submission.account)

      return if preferences['form.completed'] == false

      secret = EncryptedConfig.find_or_initialize_by(account_id: config.account_id,
                                                     key: EncryptedConfig::WEBHOOK_SECRET_KEY)&.value.to_h

      [url, secret]
    elsif params['webhook_url_id']
      webhook_url = submitter.account.webhook_urls.find(params['webhook_url_id'])

      webhook_url.url if webhook_url.events.include?('form.completed')
    end
  end
end
