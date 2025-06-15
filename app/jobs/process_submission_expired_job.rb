# frozen_string_literal: true

class ProcessSubmissionExpiredJob
  include Sidekiq::Job

  def perform(params = {})
    submission = Submission.find(params['submission_id'])

    return if submission.archived_at?
    return if submission.template&.archived_at?
    return if submission.submitters.where.not(declined_at: nil).exists?
    return unless submission.submitters.exists?(completed_at: nil)

    WebhookUrls.for_account_id(submission.account_id, %w[submission.expired]).each do |webhook|
      SendSubmissionExpiredWebhookRequestJob.perform_async('submission_id' => submission.id,
                                                           'webhook_url_id' => webhook.id)
    end
  end
end
