# frozen_string_literal: true

RSpec.describe WebhookUrls do
  describe '.for_template' do
    let(:user) { create(:user) }

    context 'with a partnership template' do
      let(:partnership) { create(:partnership) }
      let(:template) { create(:template, partnership: partnership, account: nil, author: user) }
      let!(:partnership_webhook) do
        create(:webhook_url,
               partnership: partnership,
               account: nil,
               events: ['template.created'],
               url: 'https://partnership.example.com/webhook')
      end

      it 'returns partnership webhooks' do
        webhooks = described_class.for_template(template, 'template.created')
        expect(webhooks).to include(partnership_webhook)
      end

      it 'does not return account webhooks' do
        account_webhook = create(:webhook_url, account: create(:account), events: ['template.created'])
        webhooks = described_class.for_template(template, 'template.created')
        expect(webhooks).not_to include(account_webhook)
      end

      it 'filters by event type' do
        non_matching_webhook = create(:webhook_url,
                                      partnership: partnership,
                                      account: nil,
                                      events: ['template.updated'])

        webhooks = described_class.for_template(template, 'template.created')
        expect(webhooks).to include(partnership_webhook)
        expect(webhooks).not_to include(non_matching_webhook)
      end
    end

    context 'with an account template' do
      let(:account) { create(:account) }
      let(:account_user) { create(:user, account: account) }
      let(:template) { create(:template, account: account, partnership: nil, author: account_user) }
      let!(:account_webhook) do
        create(:webhook_url,
               account: account,
               partnership: nil,
               events: ['template.created'])
      end

      it 'returns account webhooks' do
        webhooks = described_class.for_template(template, 'template.created')
        expect(webhooks).to include(account_webhook)
      end

      it 'does not return partnership webhooks' do
        partnership_webhook = create(:webhook_url,
                                     partnership: create(:partnership),
                                     account: nil,
                                     events: ['template.created'])
        webhooks = described_class.for_template(template, 'template.created')
        expect(webhooks).not_to include(partnership_webhook)
      end
    end

    context 'with a template that has neither account nor partnership' do
      let(:template) { build(:template, account: nil, partnership: nil, author: user) }

      it 'raises an ArgumentError' do
        expect do
          described_class.for_template(template, 'template.created')
        end.to raise_error(ArgumentError, 'Template must have either account_id or partnership_id')
      end
    end
  end

  describe '.for_partnership_id' do
    let(:partnership) { create(:partnership) }
    let!(:webhook) do
      create(:webhook_url,
             partnership: partnership,
             account: nil,
             events: ['template.created', 'template.updated'])
    end
    let!(:webhook_update_only) do
      create(:webhook_url,
             partnership: partnership,
             account: nil,
             events: ['template.updated'])
    end

    it 'returns webhooks matching the event' do
      webhooks = described_class.for_partnership_id(partnership.id, 'template.created')
      expect(webhooks).to include(webhook)
      expect(webhooks).not_to include(webhook_update_only)
    end

    it 'returns webhooks matching any of multiple events' do
      webhooks = described_class.for_partnership_id(partnership.id, ['template.created', 'template.updated'])
      expect(webhooks).to include(webhook, webhook_update_only)
    end

    it 'does not return webhooks from other partnerships' do
      other_partnership = create(:partnership)
      other_webhook = create(:webhook_url,
                             partnership: other_partnership,
                             account: nil,
                             events: ['template.created'])

      webhooks = described_class.for_partnership_id(partnership.id, 'template.created')
      expect(webhooks).not_to include(other_webhook)
    end

    it 'handles single event as string' do
      webhooks = described_class.for_partnership_id(partnership.id, 'template.updated')
      expect(webhooks).to include(webhook, webhook_update_only)
    end
  end

  describe '.for_account_id' do
    let(:account) { create(:account) }
    let!(:webhook) do
      create(:webhook_url,
             account: account,
             partnership: nil,
             events: ['template.created'])
    end

    it 'returns webhooks for the account' do
      webhooks = described_class.for_account_id(account.id, 'template.created')
      expect(webhooks).to include(webhook)
    end

    it 'does not return webhooks from other accounts' do
      other_account = create(:account)
      other_webhook = create(:webhook_url,
                             account: other_account,
                             partnership: nil,
                             events: ['template.created'])

      webhooks = described_class.for_account_id(account.id, 'template.created')
      expect(webhooks).not_to include(other_webhook)
    end

    it 'filters by event type' do
      non_matching = create(:webhook_url,
                            account: account,
                            partnership: nil,
                            events: ['template.updated'])

      webhooks = described_class.for_account_id(account.id, 'template.created')
      expect(webhooks).to include(webhook)
      expect(webhooks).not_to include(non_matching)
    end
  end
end
