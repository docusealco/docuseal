# frozen_string_literal: true

RSpec.describe 'Sign In' do
  let(:account) { create(:account) }
  let!(:user) { create(:user, account:, email: 'john.dou@example.com', password: 'strong_password') }

  before do
    visit new_user_session_path
  end

  context 'when only with email and password' do
    it 'signs in successfully with valid email and password' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it "doesn't sign in if the email or password are incorrect" do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'wrong_password'
      click_button 'Sign In'

      expect(page).to have_content('Invalid Email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end

  context 'when 2FA is required' do
    before do
      user.update(otp_required_for_login: true, otp_secret: User.generate_otp_secret)
    end

    it 'signs in successfully with valid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: user.current_otp
      click_button 'Sign In'

      expect(page).to have_content('Signed in successfully')
      expect(page).to have_content('Document Templates')
    end

    it 'fails to sign in with invalid OTP code' do
      fill_in 'Email', with: 'john.dou@example.com'
      fill_in 'Password', with: 'strong_password'
      click_button 'Sign In'
      fill_in 'Two-Factor Code from Authenticator App', with: '123456'
      click_button 'Sign In'

      expect(page).to have_content('Invalid Email or password')
      expect(page).not_to have_content('Document Templates')
    end
  end
end
