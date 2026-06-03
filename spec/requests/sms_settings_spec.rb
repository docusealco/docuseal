# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SMS Settings', type: :request do
  let!(:account) { create(:account) }
  let!(:admin)   { create(:user, account:, role: User::ADMIN_ROLE, email: 'admin@wabo.cc') }
  let!(:editor)  { create(:user, account:, role: User::EDITOR_ROLE, email: 'editor@wabo.cc') }

  describe 'GET /settings/sms' do
    it 'renders ok for admin' do
      sign_in admin
      get settings_sms_path

      expect(response).to have_http_status(:ok)
    end

    it 'redirects editor to root' do
      sign_in editor
      get settings_sms_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'POST /settings/sms (create)' do
    before { sign_in admin }

    it 'creates a new SMS config and redirects with notice' do
      expect do
        post settings_sms_path, params: {
          encrypted_config: {
            value: {
              enabled: '1',
              provider: 'bulkvs',
              basic_auth_token: 'tok123',
              from_number: '15551234567',
              delivery_webhook_url: ''
            }
          }
        }
      end.to change(EncryptedConfig, :count).by(1)

      expect(response).to redirect_to(settings_sms_path)
      follow_redirect!
      expect(response.body).to include(I18n.t('changes_have_been_saved'))

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['basic_auth_token']).to eq('tok123')
      expect(config.value['from_number']).to eq('15551234567')
    end

    it 'preserves existing Twilio auth token when blank is submitted' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'twilio',
               'twilio_account_sid' => 'AC123',
               'twilio_auth_token' => 'keep_me',
               'twilio_from' => '+15551234567'
             })

      post settings_sms_path, params: {
        encrypted_config: {
          value: {
            enabled: '1',
            provider: 'twilio',
            twilio_account_sid: 'AC123',
            twilio_auth_token: '',
            twilio_from: '+15551234567'
          }
        }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['twilio_auth_token']).to eq('keep_me')
    end

    it 'preserves existing BulkVS basic_auth_token when blank is submitted' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'bulkvs',
               'basic_auth_token' => 'keep_me',
               'from_number' => '15551234567'
             })

      post settings_sms_path, params: {
        encrypted_config: {
          value: { enabled: '1', provider: 'bulkvs', basic_auth_token: '', from_number: '15551234567' }
        }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['basic_auth_token']).to eq('keep_me')
    end

    it 'preserves existing VoIP.ms API password when blank is submitted' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'voipms',
               'voipms_api_username' => 'user@example.com',
               'voipms_api_password' => 'keep_me',
               'voipms_did' => '5551234567'
             })

      post settings_sms_path, params: {
        encrypted_config: {
          value: {
            enabled: '1', provider: 'voipms',
            voipms_api_username: 'user@example.com', voipms_api_password: '', voipms_did: '5551234567'
          }
        }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['voipms_api_password']).to eq('keep_me')
    end

    it 'preserves existing SignalWire API token when blank is submitted' do
      create(:encrypted_config, account:, key: EncryptedConfig::SMS_CONFIGS_KEY,
             value: {
               'enabled' => true,
               'provider' => 'signalwire',
               'signalwire_space_url' => 'test.signalwire.com',
               'signalwire_project_id' => 'uuid-1234',
               'signalwire_api_token' => 'keep_me',
               'signalwire_from' => '+15551234567'
             })

      post settings_sms_path, params: {
        encrypted_config: {
          value: {
            enabled: '1', provider: 'signalwire',
            signalwire_space_url: 'test.signalwire.com', signalwire_project_id: 'uuid-1234',
            signalwire_api_token: '', signalwire_from: '+15551234567'
          }
        }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::SMS_CONFIGS_KEY)
      expect(config.value['signalwire_api_token']).to eq('keep_me')
    end

    it 'redirects editor to root' do
      sign_in editor
      post settings_sms_path, params: {
        encrypted_config: { value: { enabled: '1', provider: 'bulkvs' } }
      }

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'POST /settings/sms/test_message' do
    before { sign_in admin }

    it 'redirects with alert when phone is blank' do
      post test_message_settings_sms_path, params: { phone: '' }

      expect(response).to redirect_to(settings_sms_path)
      follow_redirect!
      expect(response.body).to include('Enter a phone number')
    end

    it 'redirects with alert when SMS is not configured' do
      post test_message_settings_sms_path, params: { phone: '15551234567' }

      expect(response).to redirect_to(settings_sms_path)
      follow_redirect!
      expect(response.body).to include('Test failed')
    end

    it 'redirects editor to root' do
      sign_in editor
      post test_message_settings_sms_path, params: { phone: '15551234567' }

      expect(response).to redirect_to(root_path)
    end
  end
end
