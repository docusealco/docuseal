# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, '#create_careerplug_webhook' do
  around do |example|
    original_secret = ENV.fetch('CAREERPLUG_WEBHOOK_SECRET', nil)
    original_url = ENV.fetch('CAREERPLUG_WEBHOOK_URL', nil)

    # Set required env vars for webhook creation
    ENV['CAREERPLUG_WEBHOOK_SECRET'] = 'test_secret'
    ENV['CAREERPLUG_WEBHOOK_URL'] = 'http://example.com/webhook'

    example.run

    # Restore original env vars
    ENV['CAREERPLUG_WEBHOOK_SECRET'] = original_secret
    ENV['CAREERPLUG_WEBHOOK_URL'] = original_url
  end

  describe 'CareerPlug webhook creation' do
    it 'creates webhook after successful account creation' do
      account = build(:account)
      expect(account.webhook_urls).to be_empty

      account.save!

      expect(account.webhook_urls.count).to eq(1)
      webhook = account.webhook_urls.first
      expect(webhook.url).to eq('http://example.com/webhook')
      expect(webhook.events).to eq(['form.viewed', 'form.started', 'form.completed', 'form.declined'])
      expect(webhook.secret).to eq({ 'X-CareerPlug-Secret' => 'test_secret' })
    end

    it 'does not create webhook if account creation fails' do
      # This test verifies that after_commit behavior works correctly
      # by simulating a transaction rollback

      expect do
        described_class.transaction do
          create(:account)
          # Simulate some error that would cause rollback
          raise ActiveRecord::Rollback
        end
      end.not_to change(described_class, :count)

      expect do
        described_class.transaction do
          create(:account)
          raise ActiveRecord::Rollback
        end
      end.not_to change(WebhookUrl, :count)
    end

    it 'does not create webhook when CAREERPLUG_WEBHOOK_SECRET is blank' do
      original_secret = ENV.fetch('CAREERPLUG_WEBHOOK_SECRET', nil)
      ENV['CAREERPLUG_WEBHOOK_SECRET'] = ''

      account = create(:account)
      expect(account.webhook_urls.count).to eq(0)

      ENV['CAREERPLUG_WEBHOOK_SECRET'] = original_secret
    end
  end
end
