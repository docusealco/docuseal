# frozen_string_literal: true

describe Abilities::TemplateConditions do
  describe '.entity' do
    context 'when using partnership templates' do
      let(:partnership) { build(:partnership, id: 1, external_partnership_id: 'test-123') }
      let(:template) { build(:template, partnership_id: 1, account_id: nil) }

      it 'denies access for users without access tokens' do
        user = build(:user, account_id: nil)
        allow(user).to receive(:access_token).and_return(nil)
        allow(ExportLocation).to receive(:global_partnership_id).and_return(nil)

        result = described_class.entity(template, user: user)
        expect(result).to be false
      end

      it 'allows access via partnership context' do
        partnership = create(:partnership)
        template = build(:template, partnership: partnership, account_id: nil)
        user = build(:user, account_id: nil)
        allow(ExportLocation).to receive(:global_partnership_id).and_return(nil)

        request_context = { accessible_partnership_ids: [partnership.external_partnership_id] }
        result = described_class.entity(template, user: user, request_context: request_context)

        expect(result).to be true
      end

      it 'handles integer comparison in partnership context' do
        partnership = create(:partnership, external_partnership_id: 123)
        template = build(:template, partnership: partnership, account_id: nil)
        user = build(:user, account_id: nil)
        allow(ExportLocation).to receive(:global_partnership_id).and_return(nil)

        # accessible_partnership_ids are converted to integers by PartnershipContext concern
        request_context = { accessible_partnership_ids: [123] }
        result = described_class.entity(template, user: user, request_context: request_context)
        expect(result).to be true
      end

      it 'allows global partnership templates' do
        user = build(:user, account_id: 1)
        allow(ExportLocation).to receive(:global_partnership_id).and_return(1)

        result = described_class.entity(template, user: user)
        expect(result).to be true
      end
    end

    context 'when using account templates' do
      let(:template) { build(:template, account_id: 1, partnership_id: nil) }

      it 'allows access for account owners' do
        user = build(:user, account_id: 1)
        result = described_class.entity(template, user: user)
        expect(result).to be true
      end

      it 'denies access for different account users' do
        user = build(:user, account_id: 2)
        account = instance_double(Account, linked_account_account: nil)
        allow(user).to receive(:account).and_return(account)

        result = described_class.entity(template, user: user)
        expect(result).to be false
      end

      it 'allows access via partnership context with external_account_id' do
        user = build(:user, account_id: nil)
        request_context = {
          accessible_partnership_ids: ['test-123'],
          external_account_id: 'ext-123'
        }

        result = described_class.entity(template, user: user, request_context: request_context)
        expect(result).to be true
      end
    end

    it 'allows unowned templates' do
      template = build(:template, account_id: nil, partnership_id: nil)
      user = build(:user)

      result = described_class.entity(template, user: user)
      expect(result).to be true
    end
  end
end
