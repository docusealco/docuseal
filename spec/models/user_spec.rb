# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
    end

    it 'validates uniqueness of external_user_id when present' do
      account = create(:account)
      create(:user, account: account, external_user_id: 123)
      duplicate = build(:user, account: account, external_user_id: 123)
      expect(duplicate).not_to be_valid
    end
  end

  describe '.find_or_create_by_external_id' do
    let(:account) { create(:account) }
    let(:external_id) { 123 }
    let(:attributes) { { first_name: 'Test', last_name: 'User', email: 'test@example.com' } }

    it 'finds existing user by external_user_id' do
      existing_user = create(:user, account: account, external_user_id: external_id)
      result = described_class.find_or_create_by_external_id(account, external_id, attributes)
      expect(result).to eq(existing_user)
    end

    it 'creates new user when none exists' do
      result = described_class.find_or_create_by_external_id(account, external_id, attributes)
      expect(result.external_user_id).to eq(external_id)
      expect(result.first_name).to eq('Test')
      expect(result.email).to eq('test@example.com')
      expect(result.password).to be_present
    end
  end

  describe '#active_for_authentication?' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }

    it 'returns true when user and account are active' do
      expect(user.active_for_authentication?).to be true
    end

    it 'returns false when user is archived' do
      user.update!(archived_at: 1.day.ago)
      expect(user.active_for_authentication?).to be false
    end

    it 'returns false when account is archived' do
      account.update!(archived_at: 1.day.ago)
      expect(user.active_for_authentication?).to be false
    end
  end

  describe '#initials' do
    it 'returns initials from first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.initials).to eq('JD')
    end

    it 'handles missing names' do
      user = build(:user, first_name: 'John', last_name: nil)
      expect(user.initials).to eq('J')
    end
  end

  describe '#full_name' do
    it 'combines first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end

    it 'handles missing names' do
      user = build(:user, first_name: 'John', last_name: nil)
      expect(user.full_name).to eq('John')
    end
  end

  describe '#friendly_name' do
    it 'returns formatted name with email when full name present' do
      user = build(:user, first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      expect(user.friendly_name).to eq('"John Doe" <john@example.com>')
    end

    it 'returns just email when no full name' do
      user = build(:user, first_name: nil, last_name: nil, email: 'john@example.com')
      expect(user.friendly_name).to eq('john@example.com')
    end
  end
end
