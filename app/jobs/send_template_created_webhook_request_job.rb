# frozen_string_literal: true

class SendTemplateCreatedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  USER_AGENT = 'DocuSeal.co Webhook'

  MAX_ATTEMPTS = 10

  def perform(params = {})
    template = Template.find(params['template_id'])

    attempt = params['attempt'].to_i

    config = Accounts.load_webhook_config(template.account)
    url = config&.value.presence

    return if url.blank?

    preferences = Accounts.load_webhook_preferences(template.account)

    return if preferences['template.created'].blank?

    resp = begin
      Faraday.post(url,
                   {
                     event_type: 'template.created',
                     timestamp: Time.current,
                     data: Templates::SerializeForApi.call(template)
                   }.to_json,
                   **EncryptedConfig.find_or_initialize_by(account_id: config.account_id,
                                                           key: EncryptedConfig::WEBHOOK_SECRET_KEY)&.value.to_h,
                   'Content-Type' => 'application/json',
                   'User-Agent' => USER_AGENT)
    rescue Faraday::Error
      nil
    end

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || template.account.account_configs.exists?(key: :plan))
      SendTemplateCreatedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                        'template_id' => template.id,
                                                        'attempt' => attempt + 1,
                                                        'last_status' => resp&.status.to_i
                                                      })
    end
  end
end
