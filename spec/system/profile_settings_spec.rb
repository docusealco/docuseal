# frozen_string_literal: true

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

    it 'does not update if email is invalid' do
      fill_in 'Email', with: 'devid+test@example'

      all(:button, 'Update')[0].click

      expect(page).to have_content('Email is invalid')
    end
  end

  context 'when changes password' do
    it 'updates password' do
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword'
      fill_in 'Current password', with: 'password'

      all(:button, 'Update')[1].click

      expect(page).to have_content('Password has been changed')
    end

    it 'does not update if password confirmation does not match' do
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword1'
      fill_in 'Current password', with: 'password'

      all(:button, 'Update')[1].click

      expect(page).to have_content("Password confirmation doesn't match Password")
    end

    it 'does not update if current password is incorrect' do
      fill_in 'New password', with: 'newpassword'
      fill_in 'Confirm new password', with: 'newpassword'
      fill_in 'Current password', with: 'wrongpassword'

      all(:button, 'Update')[1].click

      expect(page).to have_content('Current password is invalid')
    end

    it 'resets password and signs in with new password', sidekiq: :inline do
      fill_in 'New password', with: 'newpassword'
      accept_confirm('Are you sure?') do
        find('label', text: 'Click here').click
      end

      expect(page).to have_content('You will receive an email with password reset instructions in a few minutes.')

      email = ActionMailer::Base.deliveries.last
      reset_password_url = email.body
                                .encoded[/href="([^"]+)"/, 1]
                                .sub(%r{https?://(.*?)/}, "#{Capybara.current_session.server.base_url}/")

      visit reset_password_url

      fill_in 'New password', with: 'new_strong_password'
      fill_in 'Confirm new password', with: 'new_strong_password'
      click_button 'Change my password'

      expect(page).to have_content('Your password has been changed successfully. You are now signed in.')

      visit new_user_session_path

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'new_strong_password'
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
    end
  end
end
