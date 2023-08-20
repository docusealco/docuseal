# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Email Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  context 'when SMTP settings are not set' do
    it 'setup SMTP settings' do
      visit settings_email_index_path

      fill_in 'Host', with: 'smtp.example.com'
      fill_in 'Port', with: '587'
      fill_in 'Username', with: 'user@example.com'
      fill_in 'Password', with: 'password'
      fill_in 'Domain', with: 'example.com'
      fill_in 'Send from Email', with: 'user@example.com'
      select 'Plain', from: 'Authentication'
      choose 'TLS'

      expect do
        click_button 'Save'
      end.to change(EncryptedConfig, :count).by(1)

      encrypted_config = EncryptedConfig.find_by(account:, key: EncryptedConfig::EMAIL_SMTP_KEY)

      expect(encrypted_config.value['host']).to eq('smtp.example.com')
      expect(encrypted_config.value['port']).to eq('587')
      expect(encrypted_config.value['username']).to eq('user@example.com')
      expect(encrypted_config.value['password']).to eq('password')
      expect(encrypted_config.value['domain']).to eq('example.com')
      expect(encrypted_config.value['authentication']).to eq('plain')
      expect(encrypted_config.value['security']).to eq('tls')
      expect(encrypted_config.value['from_email']).to eq('user@example.com')
    end
  end

  context 'when SMTP settings are set' do
    let!(:encrypted_config) do
      create(:encrypted_config, account:, key: EncryptedConfig::EMAIL_SMTP_KEY, value: {
               host: 'smtp.example.com',
               port: '587',
               username: 'user@example.co',
               password: 'password',
               domain: 'example.com',
               authentication: 'plain',
               security: 'tls',
               from_email: 'user@example.co'
             })
    end

    before do
      visit settings_email_index_path
    end

    it 'shows pre-filled SMTP settings' do
      expect(page).to have_content('Email SMTP')
      expect(page).to have_field('Host', with: encrypted_config.value['host'])
      expect(page).to have_field('Port', with: encrypted_config.value['port'])
      expect(page).to have_field('Username', with: encrypted_config.value['username'])
      expect(page).to have_field('Password', with: encrypted_config.value['password'])
      expect(page).to have_field('Domain', with: encrypted_config.value['domain'])
      expect(page).to have_select('Authentication', selected: 'Plain')
      expect(page).to have_field('Send from Email', with: encrypted_config.value['from_email'])
    end

    it 'updates SMTP settings' do
      fill_in 'Host', with: 'smtp.gmail.com'
      fill_in 'Port', with: '465'
      fill_in 'Username', with: 'user@gmail.com'
      fill_in 'Password', with: 'new_password'
      fill_in 'Domain', with: 'gmail.com'
      fill_in 'Send from Email', with: 'user@gmail.com'
      select 'Plain', from: 'Authentication'
      choose 'SSL'

      expect do
        click_button 'Save'
      end.not_to change(EncryptedConfig, :count)

      encrypted_config.reload

      expect(encrypted_config.value['host']).to eq('smtp.gmail.com')
      expect(encrypted_config.value['port']).to eq('465')
      expect(encrypted_config.value['username']).to eq('user@gmail.com')
      expect(encrypted_config.value['password']).to eq('new_password')
      expect(encrypted_config.value['domain']).to eq('gmail.com')
      expect(encrypted_config.value['authentication']).to eq('plain')
      expect(encrypted_config.value['security']).to eq('ssl')
      expect(encrypted_config.value['from_email']).to eq('user@gmail.com')
    end
  end
end
