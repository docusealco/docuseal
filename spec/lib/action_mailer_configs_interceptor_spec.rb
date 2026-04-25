# frozen_string_literal: true

require 'rails_helper'
require 'action_mailer_configs_interceptor'

RSpec.describe ActionMailerConfigsInterceptor do
  let(:message) do
    Mail.new do
      to      'user@example.com'
      from    'sender@example.com'
      subject 'Hi' # rubocop:disable RSpec/VariableDefinition,RSpec/VariableName
      body    'Hello'
    end
  end

  describe '.delivering_email' do
    before { allow(Rails.env).to receive(:production?).and_return(true) }

    it 'applies env SMTP settings when ExternalConfig.smtp_configured?' do
      envs = {
        'DOCUSEAL_CONFIG_SMTP_ADDRESS' => 'smtp.example.com',
        'DOCUSEAL_CONFIG_SMTP_PORT' => '2525',
        'DOCUSEAL_CONFIG_SMTP_USERNAME' => 'user',
        'DOCUSEAL_CONFIG_SMTP_PASSWORD' => 'secret'
      }
      with_env(envs) do
        described_class.delivering_email(message)
        method = message.delivery_method
        expect(method.settings[:address]).to eq('smtp.example.com')
        expect(method.settings[:port]).to eq(2525)
        expect(method.settings[:user_name]).to eq('user')
      end
    end

    it 'does not use env SMTP settings when env is absent' do
      with_env('DOCUSEAL_CONFIG_SMTP_ADDRESS' => nil) do
        allow(Rails.application.config.action_mailer).to receive(:delivery_method).and_return(nil)
        allow(Docuseal).to receive(:multitenant?).and_return(false)
        described_class.delivering_email(message)
        method = message.delivery_method
        expect(method.settings[:address]).not_to eq('smtp.example.com')
      end
    end
  end
end
