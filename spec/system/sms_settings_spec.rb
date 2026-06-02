# frozen_string_literal: true

RSpec.describe 'SMS Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows the SMS settings page with a placeholder in non-multitenant mode' do
    visit settings_sms_path

    expect(page).to have_content('SMS')
    expect(page).to have_content(I18n.t('unlock_with_docuseal_pro'))
  end
end
