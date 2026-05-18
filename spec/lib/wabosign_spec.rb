# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wabosign do
  describe '.branded_product_name' do
    context 'with no accounts in the database' do
      before { Account.delete_all }

      it 'falls back to the PRODUCT_NAME constant' do
        expect(described_class.branded_product_name).to eq(Wabosign::PRODUCT_NAME)
        expect(described_class.branded_product_name(nil)).to eq(Wabosign::PRODUCT_NAME)
      end
    end

    context 'when the passed-in account has a brand_name configured' do
      let(:account) do
        create(:account).tap do |a|
          a.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')
        end
      end

      it 'returns the account brand' do
        expect(described_class.branded_product_name(account)).to eq('Acme Sign')
      end

      it 'returns the account brand even when newer accounts also have brands' do
        newer = create(:account)
        newer.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Other Brand')
        expect(described_class.branded_product_name(account)).to eq('Acme Sign')
      end
    end

    context 'when no account is passed but the oldest account has a brand' do
      it 'uses the default-account fallback' do
        create(:account).account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Default Brand')
        create(:account) # newer, no brand
        expect(described_class.branded_product_name).to eq('Default Brand')
        expect(described_class.branded_product_name(nil)).to eq('Default Brand')
      end
    end

    context 'when the passed-in account has no brand but the default account does' do
      it 'still uses the default-account fallback' do
        create(:account).account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Default Brand')
        other = create(:account)
        expect(described_class.branded_product_name(other)).to eq('Default Brand')
      end
    end

    context 'when an archived account is the oldest' do
      it 'is skipped when looking up the default brand' do
        archived = create(:account, archived_at: Time.current)
        archived.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Archived Brand')

        live = create(:account)
        live.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Live Brand')

        expect(described_class.branded_product_name).to eq('Live Brand')
      end
    end
  end

  describe '.default_brand_account' do
    it 'returns the oldest non-archived account' do
      first = create(:account)
      _second = create(:account)
      expect(described_class.default_brand_account).to eq(first)
    end

    it 'skips archived accounts' do
      _archived = create(:account, archived_at: Time.current)
      live = create(:account)
      expect(described_class.default_brand_account).to eq(live)
    end
  end
end
