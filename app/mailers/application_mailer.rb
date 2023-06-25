# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'DocuSeal <hi@docuseal.co>'
  layout 'mailer'

  register_interceptor ActionMailerConfigsInterceptor

  def default_url_options
    Docuseal.default_url_options
  end
end
