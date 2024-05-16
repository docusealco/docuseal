# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Personalization Settings', :js do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_personalization_path
  end

  it 'shows the notifications settings page' do
    expect(page).to have_content('Email Templates')
    expect(page).to have_content('Company Logo')
    expect(page).to have_content('Submission Form')
  end
end
