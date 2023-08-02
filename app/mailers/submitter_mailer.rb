# frozen_string_literal: true

class SubmitterMailer < ApplicationMailer
  DEFAULT_MESSAGE = %(You have been invited to submit the "%<name>s" form:)

  def invitation_email(submitter, message: format(DEFAULT_MESSAGE, name: submitter.submission.template.name))
    @submitter = submitter
    @message = message

    mail(to: @submitter.email,
         subject: 'You have been invited to submit a form',
         reply_to: submitter.submission.created_by_user&.friendly_name)
  end

  def completed_email(submitter, user)
    @submitter = submitter
    @user = user

    mail(to: user.email,
         subject: %(#{submitter.email} has completed the "#{submitter.submission.template.name}" form))
  end

  def documents_copy_email(submitter)
    @submitter = submitter

    Submissions::EnsureResultGenerated.call(@submitter)

    @documents = Submitters.select_attachments_for_download(submitter)

    @documents.each do |attachment|
      attachments[attachment.filename.to_s] = attachment.download
    end

    mail(to: submitter.email, subject: 'Your copy of documents')
  end
end
