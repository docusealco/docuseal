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
           value: {
             'enabled' => true,
             'provider' => 'twilio',
             'twilio_account_sid' => 'AC123',
             'twilio_auth_token' => 'token',
             'twilio_from' => '+15551234567'
           })

    visit settings_sms_path

    expect(page).to have_content('SMS is enabled')
    expect(page).to have_content('Send a test SMS')
  end

  describe 'enable toggle visibility' do
    context 'when SMS is disabled (no saved config)' do
      it 'hides the provider section on page load' do
        visit settings_sms_path

        expect(page).to have_css('#sms_provider_section.hidden', visible: :hidden)
      end
    end

    context 'when SMS is enabled' do
      before do
        create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
               value: {
                 'enabled' => true,
                 'provider' => 'bulkvs',
                 'basic_auth_token' => 'tok',
                 'from_number' => '15551234567'
               })
      end

      it 'shows the provider section on page load' do
        visit settings_sms_path

        expect(page).to have_css('#sms_provider_section', visible: :visible)
      end
    end

    it 'shows the provider section when the toggle is turned on' do
      visit settings_sms_path

      expect(page).to have_css('#sms_provider_section.hidden', visible: :hidden)

      find('#encrypted_config_value_enabled').click

      expect(page).to have_css('#sms_provider_section', visible: :visible)
    end

    it 'hides the provider section when the toggle is turned off' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'bulkvs',
               'basic_auth_token' => 'tok',
               'from_number' => '15551234567'
             })

      visit settings_sms_path

      expect(page).to have_css('#sms_provider_section', visible: :visible)

      find('#encrypted_config_value_enabled').click

      expect(page).to have_css('#sms_provider_section.hidden', visible: :hidden)
    end
  end

  describe 'provider switching' do
    before do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'bulkvs',
               'basic_auth_token' => 'tok',
               'from_number' => '15551234567'
             })
      visit settings_sms_path
    end

    it 'shows only the BulkVS block when BulkVS is the saved provider' do
      expect(page).to have_css('[data-provider-block="bulkvs"]', visible: :visible)
      expect(page).to have_css('[data-provider-block="twilio"]', visible: :hidden)
      expect(page).to have_css('[data-provider-block="voipms"]', visible: :hidden)
      expect(page).to have_css('[data-provider-block="signalwire"]', visible: :hidden)
    end

    it 'switches to Twilio fields when Twilio is selected' do
      select 'Twilio', from: 'encrypted_config[value][provider]'

      expect(page).to have_css('[data-provider-block="twilio"]', visible: :visible)
      expect(page).to have_css('[data-provider-block="bulkvs"]', visible: :hidden)
    end

    it 'switches to VoIP.ms fields when VoIP.ms is selected' do
      select 'VoIP.ms', from: 'encrypted_config[value][provider]'

      expect(page).to have_css('[data-provider-block="voipms"]', visible: :visible)
      expect(page).to have_css('[data-provider-block="twilio"]', visible: :hidden)
    end

    it 'switches to SignalWire fields when SignalWire is selected' do
      select 'SignalWire', from: 'encrypted_config[value][provider]'

      expect(page).to have_css('[data-provider-block="signalwire"]', visible: :visible)
      expect(page).to have_css('[data-provider-block="bulkvs"]', visible: :hidden)
    end
  end

  describe 'saving settings' do
    it 'saves BulkVS configuration and shows success flash' do
      visit settings_sms_path

      find('#encrypted_config_value_enabled').click

      within('[data-provider-block="bulkvs"]') do
        fill_in 'BulkVS Basic Auth Token', with: 'mytoken123'
        fill_in 'From Number', with: '15551234567'
      end

      expect { click_button 'Save' }.to change(EncryptedConfig, :count).by(1)

      expect(page).to have_content('Changes have been saved')

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['enabled']).to eq('1')
      expect(config.value['basic_auth_token']).to eq('mytoken123')
      expect(config.value['from_number']).to eq('15551234567')
    end

    it 'retains existing Twilio auth token when left blank on re-save' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'twilio',
               'twilio_account_sid' => 'AC123',
               'twilio_auth_token' => 'secret_token',
               'twilio_from' => '+15551234567'
             })

      visit settings_sms_path

      within('[data-provider-block="twilio"]') do
        fill_in 'Twilio Account SID', with: 'AC123'
        fill_in 'From Number', with: '+15551234567'
        # Auth Token intentionally left blank — should be preserved from saved value
      end

      click_button 'Save'

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['twilio_auth_token']).to eq('secret_token')
    end
  end
end
