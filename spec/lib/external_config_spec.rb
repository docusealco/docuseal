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

  describe '.storage_configured?' do
    it 'returns true when S3_ATTACHMENTS_BUCKET is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => 'my-bucket') do
        expect(described_class.storage_configured?).to be(true)
      end
    end

    it 'returns true when GCS_BUCKET is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => 'my-gcs-bucket') do
        expect(described_class.storage_configured?).to be(true)
      end
    end

    it 'returns true when AZURE_CONTAINER is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => nil, 'AZURE_CONTAINER' => 'my-container') do
        expect(described_class.storage_configured?).to be(true)
      end
    end

    it 'returns false when no storage env var is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => nil, 'AZURE_CONTAINER' => nil) do
        expect(described_class.storage_configured?).to be(false)
      end
    end
  end

  describe '.storage_service' do
    it 'returns aws_s3 when S3_ATTACHMENTS_BUCKET is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => 'my-bucket') do
        expect(described_class.storage_service).to eq('aws_s3')
      end
    end

    it 'returns google when GCS_BUCKET is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => 'my-gcs-bucket') do
        expect(described_class.storage_service).to eq('google')
      end
    end

    it 'returns azure when AZURE_CONTAINER is set' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => nil, 'AZURE_CONTAINER' => 'my-container') do
        expect(described_class.storage_service).to eq('azure')
      end
    end
  end

  describe '.storage_settings' do
    it 'returns empty hash when not configured' do
      with_env('S3_ATTACHMENTS_BUCKET' => nil, 'GCS_BUCKET' => nil, 'AZURE_CONTAINER' => nil) do
        expect(described_class.storage_settings).to eq({})
      end
    end

    it 'returns AWS S3 config hash from env vars' do
      envs = {
        'S3_ATTACHMENTS_BUCKET' => 'my-bucket',
        'AWS_ACCESS_KEY_ID' => 'AKIAEXAMPLE',
        'AWS_SECRET_ACCESS_KEY' => 'secret123',
        'AWS_REGION' => 'ca-central-1',
        'S3_ENDPOINT' => nil
      }
      with_env(envs) do
        settings = described_class.storage_settings
        expect(settings['service']).to eq('aws_s3')
        expect(settings['configs']['bucket']).to eq('my-bucket')
        expect(settings['configs']['access_key_id']).to eq('AKIAEXAMPLE')
        expect(settings['configs']['region']).to eq('ca-central-1')
      end
    end
  end
end
