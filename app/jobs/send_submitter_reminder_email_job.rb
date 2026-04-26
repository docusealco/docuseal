# frozen_string_literal: true

class SendSubmitterReminderEmailJob
  include Sidekiq::Job

  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    return if submitter.completed_at?
    return if submitter.declined_at?
    return if submitter.submission.archived_at?
    return if submitter.template&.archived_at?
    return unless submitter.sent_at?
    return unless Accounts.can_send_invitation_emails?(submitter.account)

    reminder_index = params['reminder_index'].to_i

    return if reminder_index.positive? &&
              submitter.submission_events.exists?(event_type: 'send_reminder_email',
                                                   data: { 'reminder_index' => reminder_index })

    mail = SubmitterMailer.invitation_email(submitter)

    Submitters::ValidateSending.call(submitter, mail)

    mail.deliver_now!

    SubmissionEvent.create!(submitter: submitter,
                            event_type: 'send_reminder_email',
                            data: { reminder_index: reminder_index })
  end
end
