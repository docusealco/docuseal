# frozen_string_literal: true

RSpec.describe 'API Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_api_index_path
  end

  it 'shows verify signed PDF page' do
    expect(page).to have_content('API')
    token = user.access_token.token
    expect(page).to have_field('X-Auth-Token', with: token.sub(token[5..], '*' * token[5..].size))
  end

  it 'reveals API key with correct password' do
    find('#api_key').click

    within('.modal') do
      fill_in 'password', with: user.password
      click_button 'Submit'
    end

    expect(page).to have_field('X-Auth-Token', with: user.access_token.token)
  end

  it 'shows error with incorrect password' do
    find('#api_key').click

    within('.modal') do
      fill_in 'password', with: 'wrong_password'
      click_button 'Submit'
    end

    expect(page).to have_content('Wrong password')
  end
end
