# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def invitation_email(user)
    @user = user
    @token = @user.send(:set_reset_password_token)

    mail(to: @user.friendly_name,
         subject: 'You have been invited to Docuseal')
  end
end
