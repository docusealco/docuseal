# frozen_string_literal: true

class SubmissionMailer < ApplicationMailer
  DEFAULT_MESSAGE = "You've been invited to submit documents."

  def invitation_email(submission, message: DEFAULT_MESSAGE)
    @submission = submission
    @message = message

    mail(to: @submission.email,
         subject: 'You have been invited to submit forms')
  end

  def copy_to_submitter(submission)
    @submission = submission

    mail(to: submission.email, subject: 'Here is your copy')
  end
end
