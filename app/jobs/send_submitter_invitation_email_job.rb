# frozen_string_literal: true

class SendSubmitterInvitationEmailJob < ApplicationJob
  def perform(submitter)
    SubmitterMailer.invitation_email(submitter).deliver_now!

    submitter.sent_at ||= Time.current
    submitter.save
  end
end
