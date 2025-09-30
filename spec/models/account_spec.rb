# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  archived_at         :datetime
#  locale              :string           not null
#  name                :string           not null
#  timezone            :string           not null
#  uuid                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  external_account_id :integer
#
# Indexes
#
#  index_accounts_on_external_account_id  (external_account_id) UNIQUE
#  index_accounts_on_uuid                 (uuid) UNIQUE
#
require 'rails_helper'

RSpec.describe Account do
  describe 'validations' do
    it 'is valid with valid attributes' do
      account = build(:account)
      expect(account).to be_valid
    end

    it 'validates uniqueness of external_account_id when present' do
      create(:account, external_account_id: 123)
      duplicate = build(:account, external_account_id: 123)
      expect(duplicate).not_to be_valid
    end
  end

  describe '.find_or_create_by_external_id' do
    let(:external_id) { 123 }
    let(:name) { 'Test Account' }

    it 'finds existing account by external_account_id' do
      existing_account = create(:account, external_account_id: external_id)
      result = described_class.find_or_create_by_external_id(external_id, name)
      expect(result).to eq(existing_account)
    end

    it 'creates new account when none exists' do
      result = described_class.find_or_create_by_external_id(external_id, name)
      expect(result.external_account_id).to eq(external_id)
      expect(result.name).to eq('Test Account')
    end
  end

  describe '#testing?' do
    let(:account) { create(:account) }

    it 'delegates to linked_account_account' do
      linked_account_account = instance_double(AccountLinkedAccount, testing?: true)
      allow(account).to receive(:linked_account_account).and_return(linked_account_account)

      expect(account.testing?).to be true
    end
  end

  describe '#default_template_folder' do
    it 'creates default folder when none exists' do
      account = create(:account)
      create(:user, account: account)

      expect do
        folder = account.default_template_folder
        expect(folder.name).to eq(TemplateFolder::DEFAULT_NAME)
        expect(folder).to be_persisted
      end.to change(account.template_folders, :count).by(1)
    end
  end
end
