# frozen_string_literal: true

class SendSubmissionVoidedWebhookRequestJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks

  MAX_ATTEMPTS = 10

  def perform(params = {})
    submission = Submission.find_by(id: params['submission_id'])

    return unless submission

    webhook_url = WebhookUrl.find_by(id: params['webhook_url_id'])

    return unless webhook_url

    attempt = params['attempt'].to_i

    return if webhook_url.url.blank? || webhook_url.events.exclude?('submission.voided')

    payload = submission.as_json(only: %i[id voided_at]).merge(
      'reason' => submission.void_reason,
      'voided_by_user_id' => submission.void_event&.data&.dig('voided_by_user_id')
    )

    resp = SendWebhookRequest.call(webhook_url, event_type: 'submission.voided',
                                                event_uuid: params['event_uuid'],
                                                record: submission,
                                                attempt:,
                                                data: payload)

    if (resp.nil? || resp.status.to_i >= 400) && attempt <= MAX_ATTEMPTS &&
       (!Docuseal.multitenant? || submission.account.account_configs.exists?(key: :plan))
      SendSubmissionVoidedWebhookRequestJob.perform_in((2**attempt).minutes, {
                                                         **params,
                                                         'attempt' => attempt + 1,
                                                         'last_status' => resp&.status.to_i
                                                       })
    end
  end
end
