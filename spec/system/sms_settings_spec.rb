# frozen_string_literal: true

RSpec.describe 'SMS Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows the SMS settings page with provider form and all provider blocks' do
    visit settings_sms_path

    expect(page).to have_content('SMS')
    expect(page).to have_content('Provider')

    expect(page).to have_content('BulkVS Basic Auth Token')
  end

  it 'renders the enable toggle and provider select' do
    visit settings_sms_path

    expect(page).to have_css("input[type='checkbox'].toggle")
    expect(page).to have_css('select.base-select')
  end

  it 'shows the save button' do
    visit settings_sms_path

    expect(page).to have_button('Save')
  end

  it 'shows the test SMS section when SMS is configured and enabled' do
    create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
                               value: { 'enabled' => true, 'provider' => 'twilio',
                                        'twilio_account_sid' => 'AC123',
                                        'twilio_auth_token' => 'token',
                                        'twilio_from' => '+15551234567' })

    visit settings_sms_path

    expect(page).to have_content('SMS is enabled')
    expect(page).to have_content('Send a test SMS')
  end
end
