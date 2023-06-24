# frozen_string_literal: true

class SubmitterMailer < ApplicationMailer
  DEFAULT_MESSAGE = "You've been invited to submit the following documents:"

  def invitation_email(submitter, message: DEFAULT_MESSAGE)
    @submitter = submitter
    @message = message

    mail(to: @submitter.email,
         subject: 'You have been invited to submit forms')
  end

  def copy_to_submitter(submitter)
    @submitter = submitter

    mail(to: submitter.email, subject: 'Here is your copy')
  end
end
