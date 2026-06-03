# frozen_string_literal: true

RSpec.describe 'Account Logo' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  it 'shows the company logo section on the personalization page' do
    visit settings_personalization_path

    expect(page).to have_content(I18n.t('company_logo'))
  end

  it 'shows the logo upload form' do
    visit settings_personalization_path

    expect(page).to have_content('Upload logo')
    expect(page).to have_css('input[type="file"]')
  end

  context 'when a logo is attached' do
    before do
      logo_path = Rails.root.join('spec/fixtures/sample-image.png')
      account.logo.attach(io: File.open(logo_path), filename: 'sample-image.png',
                          content_type: 'image/png')
    end

    it 'displays the logo image on the personalization page' do
      visit settings_personalization_path

      expect(page).to have_css("img[src*='sample-image']")
    end
  end
end
