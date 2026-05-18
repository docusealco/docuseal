# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Personalization settings: brand name', type: :request do
  let!(:account) { create(:account) }
  let!(:admin)   { create(:user, account: account, role: User::ADMIN_ROLE, email: 'admin@wabo.cc') }

  before { sign_in admin }

  describe 'GET /settings/personalization' do
    it 'renders the brand-name input with the current value' do
      account.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')

      get settings_personalization_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Acme Sign"')
    end

    it 'renders an empty brand-name input when none is set' do
      get settings_personalization_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="brand_name"')
    end
  end

  describe 'POST /settings/personalization with brand_name' do
    it 'saves the brand name and redirects back' do
      post settings_personalization_path, params: {
        account_config: { key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign' }
      }

      expect(response).to redirect_to(settings_personalization_path)
      expect(account.reload.brand_name).to eq('Acme Sign')
    end

    it 'clears the brand name when posted blank' do
      account.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')

      post settings_personalization_path, params: {
        account_config: { key: AccountConfig::BRAND_NAME_KEY, value: '' }
      }

      expect(response).to redirect_to(settings_personalization_path)
      expect(account.reload.brand_name).to be_nil
    end

    it 'rejects an unknown key' do
      # Production renders 500 on this; in test env the exception propagates.
      expect do
        post settings_personalization_path, params: {
          account_config: { key: 'definitely_not_allowed', value: 'anything' }
        }
      end.to raise_error(PersonalizationSettingsController::InvalidKey)

      expect(AccountConfig.where(account: account, key: 'definitely_not_allowed')).not_to exist
    end
  end

  describe 'branded navbar' do
    it 'reflects the saved brand name in the rendered chrome' do
      account.account_configs.create!(key: AccountConfig::BRAND_NAME_KEY, value: 'Acme Sign')

      get root_path

      expect(response.body).to include('Acme Sign')
    end

    it 'shows the default brand when no override is set' do
      get root_path

      expect(response.body).to include(Wabosign::PRODUCT_NAME)
    end
  end
end
