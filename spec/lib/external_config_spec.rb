# frozen_string_literal: true

require 'rails_helper'
require 'external_config'

RSpec.describe ExternalConfig do
  describe '.smtp_configured?' do
    it 'returns true when DOCUSEAL_CONFIG_SMTP_ADDRESS is set' do
      with_env('DOCUSEAL_CONFIG_SMTP_ADDRESS' => 'smtp.example.com') do
        expect(described_class.smtp_configured?).to be(true)
      end
    end

    it 'returns false when the env var is absent' do
      with_env('DOCUSEAL_CONFIG_SMTP_ADDRESS' => nil) do
        expect(described_class.smtp_configured?).to be(false)
      end
    end
  end

  describe '.smtp_settings' do
    it 'returns an empty hash when not configured' do
      with_env('DOCUSEAL_CONFIG_SMTP_ADDRESS' => nil) do
        expect(described_class.smtp_settings).to eq({})
      end
    end

    it 'returns a hash built from env vars' do
      envs = {
        'DOCUSEAL_CONFIG_SMTP_ADDRESS' => 'smtp.example.com',
        'DOCUSEAL_CONFIG_SMTP_PORT' => '2525',
        'DOCUSEAL_CONFIG_SMTP_USERNAME' => 'user',
        'DOCUSEAL_CONFIG_SMTP_PASSWORD' => 'secret',
        'DOCUSEAL_CONFIG_SMTP_DOMAIN' => 'example.com',
        'DOCUSEAL_CONFIG_SMTP_FROM' => 'noreply@example.com'
      }
      with_env(envs) do
        settings = described_class.smtp_settings
        expect(settings[:address]).to eq('smtp.example.com')
        expect(settings[:port]).to eq(2525)
        expect(settings[:user_name]).to eq('user')
        expect(settings[:password]).to eq('secret')
        expect(settings[:domain]).to eq('example.com')
        expect(settings[:from]).to eq('noreply@example.com')
        expect(settings[:authentication]).to eq(:plain)
      end
    end
  end
end
