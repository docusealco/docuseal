# frozen_string_literal: true

RSpec.describe 'SSO Settings' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows a placeholder in single-tenant mode' do
    visit settings_sso_index_path

    expect(page).to have_content(I18n.t('unlock_with_docuseal_pro'))
  end
end
