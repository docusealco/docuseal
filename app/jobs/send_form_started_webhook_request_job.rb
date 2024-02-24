# frozen_string_literal: true

class SendFormStartedWebhookRequestJob < ApplicationJob
  USER_AGENT = 'DocuSeal.co Webhook'

  MAX_ATTEMPTS = 10

  def perform(submitter, params = {})
    attempt = params[:attempt].to_i
    config = Accounts.load_webhook_configs(submitter.submission.account)

    return if config.blank? || config.value.blank?

    ActiveStorage::Current.url_options = Docuseal.default_url_options

    resp = begin
      Faraday.post(config.value,
                   {
                     event_type: 'form.started',
                     timestamp: Time.current,
                     data: Submitters::SerializeForWebhook.call(submitter)
                   }.to_json,
                   'Content-Type' => 'application/json',
                   'User-Agent' => USER_AGENT)
    rescue Faraday::TimeoutError
      nil
    end

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || submitter.account.account_configs.exists?(key: :plan))
      SendFormStartedWebhookRequestJob.set(wait: (2**attempt).minutes)
                                      .perform_later(submitter, {
                                                       attempt: attempt + 1,
                                                       last_status: resp&.status.to_i
                                                     })
    end
  end
end
