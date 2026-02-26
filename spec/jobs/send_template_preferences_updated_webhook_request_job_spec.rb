# frozen_string_literal: true

RSpec.describe SendTemplatePreferencesUpdatedWebhookRequestJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:webhook_url) { create(:webhook_url, account:, events: ['template.preferences_updated']) }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe '#perform' do
    before do
      stub_request(:post, webhook_url.url).to_return(status: 200)
    end

    it 'sends a webhook request with minimal submitters_order data' do
      template.update!(preferences: { 'submitters_order' => 'employee_then_manager' })

      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'template.preferences_updated',
          'timestamp' => /.*/,
          'data' => {
            'id' => template.id,
            'external_account_id' => template.account&.external_account_id,
            'external_partnership_id' => template.partnership&.external_partnership_id,
            'external_id' => template.external_id,
            'application_key' => template.application_key,
            'submitters_order' => 'employee_then_manager'
          }
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook'
        }
      ).once
    end

    it 'sends a webhook request with the secret' do
      webhook_url.update(secret: { 'X-Secret-Header' => 'secret_value' })
      template.update!(preferences: { 'submitters_order' => 'simultaneous' })

      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'template.preferences_updated',
          'timestamp' => /.*/,
          'data' => {
            'id' => template.id,
            'external_account_id' => template.account&.external_account_id,
            'external_partnership_id' => template.partnership&.external_partnership_id,
            'external_id' => template.external_id,
            'application_key' => template.application_key,
            'submitters_order' => 'simultaneous'
          }
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook',
          'X-Secret-Header' => 'secret_value'
        }
      ).once
    end

    it "doesn't send a webhook request if the event is not in the webhook's events" do
      webhook_url.update!(events: ['template.created'])

      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).not_to have_requested(:post, webhook_url.url)
    end

    it 'sends again if the response status is 400 or higher' do
      stub_request(:post, webhook_url.url).to_return(status: 401)

      expect do
        described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)
      end.to change(described_class.jobs, :size).by(1)

      expect(WebMock).to have_requested(:post, webhook_url.url).once

      args = described_class.jobs.last['args'].first

      expect(args['attempt']).to eq(1)
      expect(args['last_status']).to eq(401)
      expect(args['webhook_url_id']).to eq(webhook_url.id)
      expect(args['template_id']).to eq(template.id)
    end

    it "doesn't send again if the max attempts is reached" do
      stub_request(:post, webhook_url.url).to_return(status: 401)

      expect do
        described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id, 'attempt' => 11)
      end.not_to change(described_class.jobs, :size)

      expect(WebMock).to have_requested(:post, webhook_url.url).once
    end

    it 'sends webhook with single_sided submitters_order' do
      template.update!(preferences: { 'submitters_order' => 'single_sided' })

      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'template.preferences_updated',
          'timestamp' => /.*/,
          'data' => {
            'id' => template.id,
            'external_account_id' => template.account&.external_account_id,
            'external_partnership_id' => template.partnership&.external_partnership_id,
            'external_id' => template.external_id,
            'application_key' => template.application_key,
            'submitters_order' => 'single_sided'
          }
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook'
        }
      ).once
    end
  end
end
