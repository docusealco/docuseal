# frozen_string_literal: true

class TemplateMailer < ApplicationMailer
  def otp_verification_email(template, email:)
    @current_account = template.account
    @template = template

    @otp_code = OtpChallenges.generate([email.downcase.squish, template.slug].join(':'), purpose: 'form_email_2fa')

    assign_message_metadata('otp_verification_email', template)

    from =
      if Docuseal.multitenant? &&
         AccountConfig.exists?(account_id: template.account_id, key: 'custom_otp_email', value: true)
        put_metadata('from_user_id' => template.author_id)

        template.author.friendly_name
      else
        default_params[:from]
      end

    mail(to: email, from:, subject: I18n.t('email_verification'))
  end
end
