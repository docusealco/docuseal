# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'App Setup' do
  let(:form_data) do
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@example.com',
      company_name: 'Example Company',
      password: 'password',
      app_url: 'https://example.com'
    }
  end

  before do
    visit setup_index_path
  end

  it 'shows the setup page' do
    expect(page).to have_content('Initial Setup')

    ['First name', 'Last name', 'Email', 'Company name', 'Password', 'App URL'].each do |field|
      expect(page).to have_field(field)
    end
  end

  context 'when valid information' do
    it 'setups the app' do
      fill_setup_form(form_data)

      expect do
        click_button 'Submit'
        sleep 2
      end.to change(Account, :count).by(1).and change(User, :count).by(1).and change(EncryptedConfig, :count).by(2)

      user = User.last
      encrypted_config_app_url = EncryptedConfig.find_by(account: user.account,
                                                         key: EncryptedConfig::APP_URL_KEY)
      encrypted_config_esign_certs = EncryptedConfig.find_by(account: user.account,
                                                             key: EncryptedConfig::ESIGN_CERTS_KEY)

      expect(user.first_name).to eq(form_data[:first_name])
      expect(user.last_name).to eq(form_data[:last_name])
      expect(user.email).to eq(form_data[:email])
      expect(user.account.timezone).to eq('UTC')
      expect(user.account.locale).to eq('en-US')
      expect(user.account.name).to eq(form_data[:company_name])
      expect(encrypted_config_app_url.value).to eq(form_data[:app_url])
      expect(encrypted_config_esign_certs.value).to be_present
    end
  end

  context 'when invalid information' do
    it 'does not setup the app if the password is too short' do
      fill_setup_form(form_data.merge(password: 'pass'))

      expect do
        click_button 'Submit'
      end.not_to(change(User, :count))

      expect(page).to have_content('Password is too short (minimum is 6 characters)')
    end
  end

  context 'when the app is already setup' do
    let!(:user) { create(:user, account: create(:account)) }

    it 'redirects to the dashboard page' do
      sign_in(user)
      visit setup_index_path

      expect(page).to have_link('Create', href: new_template_path)
    end
  end

  private

  def fill_setup_form(form_data)
    fill_in 'First name', with: form_data[:first_name]
    fill_in 'Last name', with: form_data[:last_name]
    fill_in 'Email', with: form_data[:email]
    fill_in 'Company name', with: form_data[:company_name]
    fill_in 'Password', with: form_data[:password]
    fill_in 'App URL', with: form_data[:app_url]
  end
end
