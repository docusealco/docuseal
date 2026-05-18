# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  describe '#brand_name' do
    let(:account) { create(:account) }

    it 'returns nil when no brand_name AccountConfig is set' do
      expect(account.brand_name).to be_nil
    end

    it 'returns the configured value' do
      account.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')
      expect(account.brand_name).to eq('Acme Sign')
    end

    it 'strips surrounding whitespace from non-blank values' do
      account.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: '  Acme Sign  ')
      expect(account.brand_name).to eq('Acme Sign')
    end
  end
end
