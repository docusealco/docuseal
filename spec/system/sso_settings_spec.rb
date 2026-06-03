# frozen_string_literal: true

RSpec.describe 'SSO Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows the Google SSO configuration form' do
    visit settings_sso_index_path

    expect(page).to have_content('Google SSO')
    expect(page).to have_content('Client ID')
    expect(page).to have_content('Client Secret')
  end
end
