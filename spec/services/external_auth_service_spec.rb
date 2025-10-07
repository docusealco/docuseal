# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalAuthService do
  describe '#authenticate_user' do
    let(:user_params) do
      {
        external_id: 123,
        email: 'test@example.com',
        first_name: 'John',
        last_name: 'Doe'
      }
    end

    context 'with account params' do
      let(:params) do
        {
          account: { external_id: 456, name: 'Test Account' },
          user: user_params
        }
      end

      it 'returns access token for new account and user' do
        token = described_class.new(params).authenticate_user

        expect(token).to be_present
        expect(Account.last.external_account_id).to eq(456)
        expect(User.last.external_user_id).to eq(123)
      end

      it 'returns access token for existing user' do
        account = create(:account, external_account_id: 456)
        user = create(:user, account: account, external_user_id: 123)

        token = described_class.new(params).authenticate_user

        expect(token).to eq(user.access_token.token)
      end
    end

    context 'with account_group params' do
      let(:params) do
        {
          account_group: { external_id: 789, name: 'Test Group' },
          user: user_params
        }
      end

      it 'returns access token for new account_group and user' do
        token = described_class.new(params).authenticate_user

        expect(token).to be_present
        expect(AccountGroup.last.external_account_group_id).to eq(789)
        expect(User.last.external_user_id).to eq(123)
      end
    end

    context 'with invalid params' do
      it 'raises error when neither account nor account_group provided' do
        params = { user: user_params }

        expect { described_class.new(params).authenticate_user }
          .to raise_error(ArgumentError, 'Either account or account_group params must be provided')
      end
    end
  end
end
