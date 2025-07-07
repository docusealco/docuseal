# frozen_string_literal: true

class ProcessSubmissionExpiredJob
  include Sidekiq::Job

  def perform(params = {})
    submission = Submission.find(params['submission_id'])

    return if submission.archived_at?
    return if submission.template&.archived_at?
    return if submission.submitters.where.not(declined_at: nil).exists?
    return unless submission.submitters.exists?(completed_at: nil)

    WebhookUrls.enqueue_events(submission, 'submission.expired')
  end
end
