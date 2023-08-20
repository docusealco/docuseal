# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
    visit settings_api_index_path
  end

  it 'shows verify signed PDF page' do
    expect(page).to have_content('API')
    expect(page).to have_field('X-Auth-Token', with: user.access_token.token)
  end
end
