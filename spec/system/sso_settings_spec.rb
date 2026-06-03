# frozen_string_literal: true

RSpec.describe 'SSO Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows SSO settings page' do
    visit settings_sso_index_path

    expect(page).to have_content('SSO')
    expect(page).to have_content('SAML_CONFIGS')
  end
end
