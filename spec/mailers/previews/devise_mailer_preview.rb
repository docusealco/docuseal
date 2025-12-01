# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def reset_password_instructions
    user = User.first
    user.send_reset_password_instructions
    Devise::Mailer.reset_password_instructions(user, user.reset_password_token)
  end
end
