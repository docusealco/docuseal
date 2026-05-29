# frozen_string_literal: true

RSpec.describe 'Templates Upload' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  context 'when url param is present' do
    let(:file_url) { 'https://example.com/document.pdf' }

    before do
      stub_request(:get, file_url).to_return(
        body: Rails.root.join('spec/fixtures/sample-document.pdf').read,
        headers: { 'Content-Type' => 'application/pdf' }
      )
    end

    it 'shows a confirm page and creates template on submit' do
      visit "/new?url=#{CGI.escape(file_url)}"

      expect(page).to have_text('Open file from')
      expect(page).to have_link('example.com/document.pdf')

      click_button 'Open'

      expect(Template.last.name).to eq('document')
    end
  end

  context 'when url param is missing' do
    it 'redirects to root' do
      visit '/new'

      expect(page).to have_current_path(root_path)
    end
  end
end
