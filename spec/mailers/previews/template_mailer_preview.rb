# frozen_string_literal: true

class TemplateMailerPreview < ActionMailer::Preview
  def otp_verification_email
    template = Template.active.last

    TemplateMailer.otp_verification_email(template, email: 'john.doe@example.com')
  end
end
