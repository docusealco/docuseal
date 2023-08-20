# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Newsletter' do
  let(:user) { create(:user, account: create(:account)) }

  before do
    sign_in(user)
    stub_request(:post, Docuseal::NEWSLETTER_URL).to_return(status: 200)
    visit newsletter_path
  end

  it 'shows the newsletter page' do
    expect(page).to have_content('Developer Newsletters')
    expect(page).to have_button('Submit')
    expect(page).to have_content('Skip')
    expect(page).to have_field('user[email]', with: user.email)
  end

  it 'submits the newsletter form' do
    click_button 'Submit'

    expect(a_request(:post, Docuseal::NEWSLETTER_URL)).to have_been_made.once
  end

  it 'skips the newsletter form' do
    click_on 'Skip'

    expect(page).to have_current_path(root_path, ignore_query: true)
  end
end
