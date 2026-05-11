# frozen_string_literal: true

class SendSubmitterReminderEmailJob
  include Sidekiq::Job

  sidekiq_options queue: :mailers

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    return if submitter.completed_at?
    return if submitter.declined_at?
    return if submitter.submission.archived_at?
    return if submitter.template&.archived_at?
    return unless submitter.email.to_s.include?('@')
    return unless Accounts.can_send_emails?(submitter.account)
    return if submitter.submission_events.where(event_type: 'send_reminder_email')
                       .where('created_at > ?', 1.minute.ago).exists?

    mail = SubmitterMailer.reminder_email(submitter)

    mail.deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_reminder_email')
  end
end
