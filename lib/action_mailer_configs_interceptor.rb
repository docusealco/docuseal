# frozen_string_literal: true

module ActionMailerConfigsInterceptor
  module_function

  def delivering_email(message)
    return message unless Rails.env.production?

    email_configs = EncryptedConfig.find_by(key: EncryptedConfig::EMAIL_SMTP_KEY)

    if email_configs
      message.delivery_method(:smtp, user_name: email_configs.value['username'],
                                     password: email_configs.value['password'],
                                     address: email_configs.value['host'],
                                     port: email_configs.value['port'],
                                     tls: email_configs.value['port'].to_s == '465')

      message.from = email_configs.value['from_email']
    else
      message.delivery_method(:test)
    end

    message
  end
end
