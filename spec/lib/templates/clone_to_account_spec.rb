# frozen_string_literal: true

describe Templates::CloneToAccount do
  let(:author) { build(:user, id: 1) }

  describe '.call' do
    context 'with partnership template' do
      let(:partnership_template) { build(:template, id: 1, partnership_id: 2, account_id: nil) }
      let(:target_account) { build(:account, id: 3) }

      it 'clones partnership template to account' do
        allow(Templates::Clone).to receive(:call).and_return(build(:template))

        result = described_class.call(partnership_template, author: author, target_account: target_account)

        expect(Templates::Clone).to have_received(:call).with(
          partnership_template,
          author: author,
          external_id: nil,
          name: nil,
          folder_name: nil,
          target_account: target_account
        )
        expect(result.template_accesses).to be_empty
      end

      it 'validates partnership template requirement' do
        account_template = build(:template, partnership_id: nil, account_id: 1)

        expect do
          described_class.call(account_template, author: author, target_account: target_account)
        end.to raise_error(ArgumentError, 'Template must be a partnership template')
      end
    end

    context 'with external_account_id' do
      let(:partnership_template) { build(:template, partnership_id: 2, account_id: nil) }
      let(:current_user) { build(:user, account_id: 3) }
      let(:target_account) { build(:account, id: 3, external_account_id: 'ext-123') }

      it 'finds account by external_account_id' do
        allow(Account).to receive(:find_by).with(external_account_id: 'ext-123').and_return(target_account)
        allow(Templates::Clone).to receive(:call).and_return(build(:template))

        described_class.call(partnership_template,
                             author: author,
                             external_account_id: 'ext-123',
                             current_user: current_user)

        expect(Account).to have_received(:find_by).with(external_account_id: 'ext-123')
      end

      it 'validates user authorization' do
        other_user = build(:user, account_id: 999)
        allow(Account).to receive(:find_by).and_return(target_account)

        expect do
          described_class.call(partnership_template,
                               author: author,
                               external_account_id: 'ext-123',
                               current_user: other_user)
        end.to raise_error(ArgumentError, 'Unauthorized access to target account')
      end
    end
  end
end
