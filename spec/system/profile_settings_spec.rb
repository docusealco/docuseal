# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile Settings' do
  let(:user) { create(:user, account: create(:account)) }

  before do
    sign_in(user)
    visit settings_profile_index_path
  end

  it 'shows the profile settings page' do
    expect(page).to have_content('Profile')
    expect(page).to have_field('user[email]', with: user.email)
    expect(page).to have_field('user[first_name]', with: user.first_name)
    expect(page).to have_field('user[last_name]', with: user.last_name)

    expect(page).to have_content('Change Password')
    expect(page).to have_field('user[password]')
    expect(page).to have_field('user[password_confirmation]')
  end

  context 'when changes contact information' do
    it 'updates first name, last name and email' do
      fill_in 'First name', with: 'Devid'
      fill_in 'Last name', with: 'Beckham'
      fill_in 'Email', with: 'david.beckham@example.com'

      all(:button, 'Update')[0].click

      user.reload

      expect(user.first_name).to eq('Devid')
      expect(user.last_name).to eq('Beckham')
      expect(user.email).to eq('david.beckham@example.com')
    end
  end

  context 'when changes password' do
    it 'updates password' do
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword'

      all(:button, 'Update')[1].click

      expect(page).to have_content('Password has been changed')
    end

    it 'does not update if password confirmation does not match' do
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword1'

      all(:button, 'Update')[1].click

      expect(page).to have_content("Password confirmation doesn't match Password")
    end
  end
end
