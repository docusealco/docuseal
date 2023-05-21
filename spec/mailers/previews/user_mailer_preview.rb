# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def invitation_email
    UserMailer.invitation_email(User.last)
  end
end
