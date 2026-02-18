# frozen_string_literal: true

# == Schema Information
#
# Table name: webhook_urls
#
#  id             :bigint           not null, primary key
#  events         :text             not null
#  secret         :text             not null
#  sha1           :string           not null
#  url            :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer
#  partnership_id :bigint
#
# Indexes
#
#  index_webhook_urls_on_account_id      (account_id)
#  index_webhook_urls_on_partnership_id  (partnership_id)
#  index_webhook_urls_on_sha1            (sha1)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (partnership_id => partnerships.id)
#
describe WebhookUrl do
  describe 'validations' do
    context 'with owner presence' do
      it 'is valid with account_id and no partnership_id' do
        webhook = build(:webhook_url, account: create(:account), partnership: nil)
        expect(webhook).to be_valid
      end

      it 'is valid with partnership_id and no account_id' do
        # Disable webhook creation callback by removing env vars
        stub_const('ENV', ENV.to_hash.except('CAREERPLUG_WEBHOOK_URL', 'CAREERPLUG_WEBHOOK_SECRET'))

        partnership = create(:partnership)
        webhook = build(:webhook_url,
                        account: nil,
                        partnership: partnership,
                        events: WebhookUrl::PARTNERSHIP_EVENTS)
        expect(webhook).to be_valid
      end

      it 'is invalid with both account_id and partnership_id' do
        stub_const('ENV', ENV.to_hash.except('CAREERPLUG_WEBHOOK_URL', 'CAREERPLUG_WEBHOOK_SECRET'))

        webhook = build(:webhook_url, account: create(:account), partnership: create(:partnership))
        expect(webhook).not_to be_valid
        expect(webhook.errors[:base]).to include('Must have either account_id or partnership_id, but not both')
      end

      it 'is invalid with neither account_id nor partnership_id' do
        webhook = build(:webhook_url, account: nil, partnership: nil)
        expect(webhook).not_to be_valid
        expect(webhook.errors[:base]).to include('Must have either account_id or partnership_id, but not both')
      end
    end

    context 'with partnership events constraint' do
      it 'only includes template.* events in PARTNERSHIP_EVENTS' do
        expect(WebhookUrl::PARTNERSHIP_EVENTS).to all(start_with('template.'))
      end

      it 'PARTNERSHIP_EVENTS is a subset of EVENTS' do
        expect(WebhookUrl::PARTNERSHIP_EVENTS).to all(be_in(WebhookUrl::EVENTS))
      end
    end
  end

  describe 'callbacks' do
    describe '#set_sha1' do
      it 'sets sha1 based on url' do
        webhook = build(:webhook_url, url: 'https://example.com/webhook')
        webhook.valid?
        expect(webhook.sha1).to eq(Digest::SHA1.hexdigest('https://example.com/webhook'))
      end

      it 'updates sha1 when url changes' do
        webhook = create(:webhook_url, url: 'https://example.com/webhook')
        original_sha1 = webhook.sha1

        webhook.url = 'https://example.com/new-webhook'
        webhook.valid?

        expect(webhook.sha1).not_to eq(original_sha1)
        expect(webhook.sha1).to eq(Digest::SHA1.hexdigest('https://example.com/new-webhook'))
      end
    end
  end
end
