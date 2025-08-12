# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendFormChangesRequestedWebhookRequestJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:template) { create(:template, account: account, author: user) }
  let(:submission) { create(:submission, template: template, created_by_user: user) }
  let(:submitter) do
    create(
      :submitter, submission: submission, uuid: template.submitters.first['uuid'], changes_requested_at: Time.current
    )
  end
  let(:webhook_url) { create(:webhook_url, account: account, events: ['form.changes_requested']) }

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
          'event_type' => 'form.changes_requested',
          'timestamp' => /.*/,
          'data' => JSON.parse(Submitters::SerializeForWebhook.call(submitter.reload).to_json)
        },
        headers: {
          'Content-Type' => 'application/json',
          'User-Agent' => 'DocuSeal.com Webhook'
        }
      ).once
    end

    it "doesn't send a webhook request if the event is not in the webhook's events" do
      webhook_url.update!(events: ['form.completed'])

      described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)

      expect(WebMock).not_to have_requested(:post, webhook_url.url)
    end

    it 'retries on failure' do
      stub_request(:post, webhook_url.url).to_return(status: 500)

      expect do
        described_class.new.perform('submitter_id' => submitter.id, 'webhook_url_id' => webhook_url.id)
      end.to change(described_class.jobs, :size).by(1)

      expect(WebMock).to have_requested(:post, webhook_url.url).once
    end
  end
end
