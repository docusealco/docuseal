# frozen_string_literal: true

RSpec.describe SendTemplateCreatedWebhookRequestJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:webhook_url) { create(:webhook_url, account:, events: ['template.created']) }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe '#perform' do
    before do
      stub_request(:post, webhook_url.url).to_return(status: 200)
    end

    it 'sends a webhook request' do
      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'template.created',
          'timestamp' => /.*/,
          'data' => JSON.parse(Templates::SerializeForApi.call(template.reload).to_json)
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook'
        }
      ).once
    end

    it 'sends a webhook request with the secret' do
      webhook_url.update(secret: { 'X-Secret-Header' => 'secret_value' })
      described_class.new.perform('template_id' => template.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'template.created',
          'timestamp' => /.*/,
          'data' => JSON.parse(Templates::SerializeForApi.call(template.reload).to_json)
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook',
          'X-Secret-Header' => 'secret_value'
        }
      ).once
    end

    it "doesn't send a webhook request if the event is not in the webhook's events" do
      webhook_url.update!(events: ['template.updated'])

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

    context 'with partnership template' do
      let(:partnership) { create(:partnership) }
      let(:partnership_template) { create(:template, partnership: partnership, account: nil, author: user) }
      let(:partnership_webhook) do
        create(:webhook_url,
               partnership: partnership,
               account: nil,
               events: ['template.created'],
               url: 'https://partnership.example.com/webhook')
      end

      before do
        stub_request(:post, partnership_webhook.url).to_return(status: 200)
      end

      it 'sends a webhook request for partnership template' do
        described_class.new.perform(
          'template_id' => partnership_template.id,
          'webhook_url_id' => partnership_webhook.id
        )

        expect(WebMock).to have_requested(:post, partnership_webhook.url).with(
          body: {
            'event_type' => 'template.created',
            'timestamp' => /.*/,
            'data' => JSON.parse(Templates::SerializeForApi.call(partnership_template.reload).to_json)
          },
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'DocuSeal.com Webhook'
          }
        ).once
      end

      it 'sends a webhook request with the partnership secret' do
        partnership_webhook.update(secret: { 'X-Partnership-Secret' => 'partnership_secret' })
        described_class.new.perform(
          'template_id' => partnership_template.id,
          'webhook_url_id' => partnership_webhook.id
        )

        expect(WebMock).to have_requested(:post, partnership_webhook.url).with(
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'DocuSeal.com Webhook',
            'X-Partnership-Secret' => 'partnership_secret'
          }
        ).once
      end

      it 'retries on failure for partnership template' do
        stub_request(:post, partnership_webhook.url).to_return(status: 500)

        expect do
          described_class.new.perform(
            'template_id' => partnership_template.id,
            'webhook_url_id' => partnership_webhook.id
          )
        end.to change(described_class.jobs, :size).by(1)

        expect(WebMock).to have_requested(:post, partnership_webhook.url).once

        args = described_class.jobs.last['args'].first
        expect(args['attempt']).to eq(1)
        expect(args['last_status']).to eq(500)
      end
    end
  end
end
