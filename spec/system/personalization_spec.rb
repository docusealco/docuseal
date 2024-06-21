# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Personalization' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_personalization_path
  end

  it 'shows the personalization page' do
    expect(page).to have_content('Email Templates')
    expect(page).to have_content('Signature Request Email')
    expect(page).to have_content('Completed Notification Email')
    expect(page).to have_content('Documents Copy Email')
    expect(page).to have_content('Company Logo')
    expect(page).to have_content('Unlock with DocuSeal Pro')
    expect(page).to have_content('Display your company name and logo when signing documents')
  end
end
