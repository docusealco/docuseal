# frozen_string_literal: true

class SendSubmissionArchivedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  USER_AGENT = 'DocuSeal.co Webhook'

  MAX_ATTEMPTS = 10

  def perform(params = {})
    submission = Submission.find(params['submission_id'])

    attempt = params['attempt'].to_i
    url = Accounts.load_webhook_url(submission.account)

    return if url.blank?

    preferences = Accounts.load_webhook_preferences(submission.account)

    return if preferences['submission.archived'].blank?

    resp = begin
      Faraday.post(url,
                   {
                     event_type: 'submission.archived',
                     timestamp: Time.current,
                     data: submission.as_json(only: %i[id archived_at])
                   }.to_json,
                   'Content-Type' => 'application/json',
                   'User-Agent' => USER_AGENT)
    rescue Faraday::Error
      nil
    end

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || submission.account.account_configs.exists?(key: :plan))
      SendSubmissionArchivedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                           'submission_id' => submission.id,
                                                           'attempt' => attempt + 1,
                                                           'last_status' => resp&.status.to_i
                                                         })
    end
  end
end
