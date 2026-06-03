# frozen_string_literal: true

RSpec.describe 'SMS Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows the SMS settings page with provider form' do
    visit settings_sms_path

    expect(page).to have_content('SMS')
    expect(page).to have_content('Provider')
    expect(page).to have_select('Provider')
  end
end
