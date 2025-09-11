# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountGroupValidation do
  # Test with User model since it includes the concern
  describe 'validation' do
    context 'with account only' do
      it 'is valid' do
        user = build(:user, account: create(:account), account_group: nil)
        expect(user).to be_valid
      end
    end

    context 'with account_group only' do
      it 'is valid' do
        user = build(:user, account: nil, account_group: create(:account_group))
        expect(user).to be_valid
      end
    end

    context 'with neither account nor account_group' do
      it 'is invalid' do
        user = build(:user, account: nil, account_group: nil)
        expect(user).not_to be_valid
        expect(user.errors[:base]).to include('Must belong to either an account or account group')
      end
    end

    context 'with both account and account_group' do
      it 'is invalid' do
        user = build(:user, account: create(:account), account_group: create(:account_group))
        expect(user).not_to be_valid
        expect(user.errors[:base]).to include('Cannot belong to both account and account group')
      end
    end
  end
end
