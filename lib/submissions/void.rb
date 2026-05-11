# frozen_string_literal: true

module Submissions
  module Void
    NotVoidableError = Class.new(StandardError)
    ReasonRequiredError = Class.new(StandardError)

    module_function

    def call(submission, user:, reason:, request: nil)
      reason = reason.to_s.strip
      raise ReasonRequiredError, I18n.t('void_reason_is_required') if reason.blank?
      raise NotVoidableError, I18n.t('submission_cannot_be_voided') unless submission.voidable?

      ApplicationRecord.transaction do
        submission.update!(voided_at: Time.current)

        SubmissionEvent.create!(
          submission:,
          event_type: :void_submission,
          data: {
            reason:,
            voided_by_user_id: user&.id,
            ip: request&.remote_ip,
            ua: request&.user_agent
          }.compact_blank
        )
      end

      notify_submitters(submission, user)
      WebhookUrls.enqueue_events(submission, 'submission.voided')
      GenerateVoidedDocumentsJob.perform_async('submission_id' => submission.id)

      submission
    end

    def notify_submitters(submission, user)
      submission.submitters.each do |submitter|
        next if submitter.email.blank?
        next if submitter.sent_at.blank?

        SubmitterMailer.voided_email(submitter, user).deliver_later!
      end
    end
  end
end
