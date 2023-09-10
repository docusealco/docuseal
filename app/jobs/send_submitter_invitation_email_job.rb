# frozen_string_literal: true

class SendSubmitterInvitationEmailJob < ApplicationJob
  def perform(submitter)
    SubmitterMailer.invitation_email(submitter).deliver_now!

    SubmissionEvent.create!(submitter:, event_type: 'send_email')

    submitter.sent_at ||= Time.current
    submitter.save
  end
end
