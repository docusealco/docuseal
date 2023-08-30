# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PDF Signature Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_esign_path
  end

  it 'shows verify signed PDF page' do
    expect(page).to have_content('PDF Signature')
    expect(page).to have_content('Upload signed PDF file to validate its signature')
    expect(page).to have_content('Verify Signed PDF')
    expect(page).to have_content('Click to upload or drag and drop files')
  end
end
