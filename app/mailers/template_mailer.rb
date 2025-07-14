# frozen_string_literal: true

class TemplateMailer < ApplicationMailer
  def otp_verification_email(template, email:)
    @template = template

    @otp_code = EmailVerificationCodes.generate([email.downcase.strip, template.slug].join(':'))

    assign_message_metadata('otp_verification_email', template)

    mail(to: email, subject: I18n.t('email_verification'))
  end
end
