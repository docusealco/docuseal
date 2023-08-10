# frozen_string_literal: true

class SettingsMailerPreview < ActionMailer::Preview
  def smtp_successful_setup
    SettingsMailer.smtp_successful_setup('example@gmail.com')
  end
end
