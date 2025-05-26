# frozen_string_literal: true

RSpec.describe SendFormViewedWebhookRequestJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }
  let(:template) { create(:template, account:, author: user) }
  let(:submission) { create(:submission, template:, created_by_user: user) }
  let(:submitter) do
    create(:submitter, submission:, uuid: template.submitters.first['uuid'], completed_at: Time.current)
  end
  let(:webhook_url) { create(:webhook_url, account:, events: ['form.viewed']) }

  before do
    create(:encrypted_config, key: EncryptedConfig::ESIGN_CERTS_KEY,
                              value: GenerateCertificate.call.transform_values(&:to_pem))
  end

  describe '#perform' do
    before do
      stub_request(:post, webhook_url.url).to_return(status: 200)
    end

    it 'sends a webhook request' do
      described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'form.viewed',
          'timestamp' => /.*/,
          'data' => JSON.parse(Submitters::SerializeForWebhook.call(submitter.reload).to_json)
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook'
        }
      ).once
    end

    it 'sends a webhook request with the secret' do
      webhook_url.update(secret: { 'X-Secret-Header' => 'secret_value' })
      described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).to have_requested(:post, webhook_url.url).with(
        body: {
          'event_type' => 'form.viewed',
          'timestamp' => /.*/,
          'data' => JSON.parse(Submitters::SerializeForWebhook.call(submitter.reload).to_json)
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook',
          'X-Secret-Header' => 'secret_value'
        }
      ).once
    end

    it "doesn't send a webhook request if the event is not in the webhook's events" do
      webhook_url.update!(events: ['form.started'])

      described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).not_to have_requested(:post, webhook_url.url)
    end

    it 'sends again if the response status is 400 or higher' do
      stub_request(:post, webhook_url.url).to_return(status: 401)

      expect do
        described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)
      end.to change(described_class.jobs, :size).by(1)

      expect(WebMock).to have_requested(:post, webhook_url.url).once

      args = described_class.jobs.last['args'].first

      expect(args['attempt']).to eq(1)
      expect(args['last_status']).to eq(401)
      expect(args['webhook_url_id']).to eq(webhook_url.id)
      expect(args['submitter_id']).to eq(submitter.id)
    end

    it "doesn't send again if the max attempts is reached" do
      stub_request(:post, webhook_url.url).to_return(status: 401)

      expect do
        described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id, 'attempt' => 11)
      end.not_to change(described_class.jobs, :size)

      expect(WebMock).to have_requested(:post, webhook_url.url).once
    end
  end
end
