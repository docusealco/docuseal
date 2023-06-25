# frozen_string_literal: true

class SubmitterMailerPreview < ActionMailer::Preview
  def invitation_email
    SubmitterMailer.invitation_email(Submitter.last)
  end

  def completed_email
    submitter = Submitter.where.not(completed_at: nil).joins(:documents_attachments).last

    SubmitterMailer.completed_email(submitter, User.last)
  end

  def documents_copy_email
    submitter = Submitter.where.not(completed_at: nil).joins(:documents_attachments).last

    SubmitterMailer.documents_copy_email(submitter)
  end
end
