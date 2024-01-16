# frozen_string_literal: true

class SendSubmitterInvitationEmailJob < ApplicationJob
  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    mail = SubmitterMailer.invitation_email(submitter)

    Submitters::ValidateSending.call(submitter, mail)

    mail.deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_email')

    submitter.sent_at ||= Time.current
    submitter.save
  end
end
