# frozen_string_literal: true

class SettingsMailer < ApplicationMailer
  def smtp_successful_setup(email)
    mail(to: email, from: email, subject: 'SMTP has been configured')
  end
end
