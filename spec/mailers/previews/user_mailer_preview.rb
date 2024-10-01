# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def invitation_email
    user = User.first
    user.account.locale = I18n.locale
    UserMailer.invitation_email(user)
  end
end
