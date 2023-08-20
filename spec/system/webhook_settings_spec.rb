# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webhook Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_webhooks_path
  end

  it 'shows webhook settings page' do
    expect(page).to have_content('Webhooks')
    expect(page).to have_field('Webhook URL')
    expect(page).to have_button('Save')
  end

  it 'updates the webhook URL' do
    fill_in 'Webhook URL', with: 'https://example.com'

    expect do
      click_button 'Save'
    end.to change(EncryptedConfig, :count).by(1)

    encrypted_config = EncryptedConfig.find_by(account:, key: EncryptedConfig::WEBHOOK_URL_KEY)

    expect(encrypted_config.value).to eq('https://example.com')
  end
end
