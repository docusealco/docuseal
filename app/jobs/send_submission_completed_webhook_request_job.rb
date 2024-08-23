# frozen_string_literal: true

class SendSubmissionCompletedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  USER_AGENT = 'DocuSeal.co Webhook'

  MAX_ATTEMPTS = 10

  def perform(params = {})
    submission = Submission.find(params['submission_id'])

    attempt = params['attempt'].to_i

    webhook_url = submission.account.webhook_urls.find(params['webhook_url_id'])

    url = webhook_url.url if webhook_url.events.include?('submission.completed')

    return if url.blank?

    resp = begin
      Faraday.post(url,
                   {
                     event_type: 'submission.completed',
                     timestamp: Time.current,
                     data: Submissions::SerializeForApi.call(submission)
                   }.to_json,
                   **EncryptedConfig.find_or_initialize_by(account_id: submission.account_id,
                                                           key: EncryptedConfig::WEBHOOK_SECRET_KEY)&.value.to_h,
                   'Content-Type' => 'application/json',
                   'User-Agent' => USER_AGENT)
    rescue Faraday::Error
      nil
    end

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || submission.account.account_configs.exists?(key: :plan))
      SendSubmissionCompletedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                            **params,
                                                            'attempt' => attempt + 1,
                                                            'last_status' => resp&.status.to_i
                                                          })
    end
  end
end
