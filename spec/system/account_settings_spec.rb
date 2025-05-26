# frozen_string_literal: true

RSpec.describe 'Account Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:encrypted_config) { create(:encrypted_config, account:, key: EncryptedConfig::APP_URL_KEY, value: 'https://www.test.com') }

  before do
    sign_in(user)
    visit settings_account_path
  end

  it 'shows pre-filled account settings page' do
    expect(page).to have_content('Account')
    expect(page).to have_field('Company name', with: account.name)
    expect(page).to have_field('Time zone', with: account.timezone)
    expect(page).to have_field('Language', with: account.locale)
    expect(page).to have_field('App URL', with: encrypted_config.value)
  end

  it 'updates the account settings' do
    fill_in 'Company name', with: 'New Company Name'
    fill_in 'App URL', with: 'https://example.com'
    select '(GMT+01:00) Berlin', from: 'Time zone'
    select 'Español', from: 'Language'

    click_button 'Update'

    account.reload
    encrypted_config.reload

    expect(account.name).to eq('New Company Name')
    expect(account.timezone).to eq('Berlin')
    expect(account.locale).to eq('es-ES')
    expect(encrypted_config.value).to eq('https://example.com')
  end

  it 'changes the account language' do
    select 'Deutsch', from: 'Language'

    click_button 'Update'

    account.reload
    encrypted_config.reload

    expect(account.locale).to eq('de-DE')
    expect(page).to have_content('Konto')
    expect(page).to have_field('Firmenname', with: account.name)
    expect(page).to have_field('Zeitzone', with: account.timezone)
    expect(page).to have_field('Sprache', with: account.locale)
    expect(page).to have_field('App-URL', with: encrypted_config.value)
    expect(page).to have_button('Aktualisieren')
  end
end
