# frozen_string_literal: true

class SendSubmitterInvitationEmailJob < ApplicationJob
  def perform(params = {})
    submitter = Submitter.find(params['submitter_id'])

    SubmitterMailer.invitation_email(submitter, subject: params['subject'], body: params['body']).deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_email')

    submitter.sent_at ||= Time.current
    submitter.save
  end
end
