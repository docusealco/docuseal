# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Google OAuth2 callback', type: :request do
  let!(:account) { create(:account) }
  # ApplicationController redirects to /setup when no users exist; create a
  # placeholder admin so that branch doesn't fire during these specs.
  let!(:placeholder_admin) { create(:user, account: account, email: 'admin@wabo.cc') }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Rails.logger

    stub_const('Wabosign::GOOGLE_CLIENT_ID', 'test-client-id')
    stub_const('Wabosign::GOOGLE_CLIENT_SECRET', 'test-client-secret')
    stub_const('Wabosign::GOOGLE_ALLOWED_DOMAINS', ['wabo.cc'].freeze)
    stub_const('Wabosign::GOOGLE_DEFAULT_ACCOUNT_ID', nil)
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def stub_google_auth(email:, uid: '1234567890', hd: 'wabo.cc', first_name: 'Test', last_name: 'User')
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2',
      uid: uid,
      info: { email: email, first_name: first_name, last_name: last_name },
      extra: { raw_info: OmniAuth::AuthHash.new(hd: hd) }
    )
  end

  describe 'happy path: new email, allowed domain' do
    it 'creates the user in the default account and signs them in' do
      stub_google_auth(email: 'new.user@wabo.cc')

      expect do
        post user_google_oauth2_omniauth_callback_path
      end.to change(User, :count).by(1)

      user = User.find_by(email: 'new.user@wabo.cc')
      expect(user.provider).to eq('google_oauth2')
      expect(user.uid).to eq('1234567890')
      expect(user.account).to eq(account)
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'existing user with matching email, no provider yet' do
    let!(:user) { create(:user, account: account, email: 'existing@wabo.cc') }

    it 'links the Google identity and signs the user in' do
      stub_google_auth(email: 'existing@wabo.cc', uid: 'google-uid-99')

      expect do
        post user_google_oauth2_omniauth_callback_path
      end.not_to change(User, :count)

      user.reload
      expect(user.provider).to eq('google_oauth2')
      expect(user.uid).to eq('google-uid-99')
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'disallowed Workspace domain' do
    it 'redirects back to sign-in with a flash' do
      stub_google_auth(email: 'outsider@evil.com', hd: 'evil.com')

      expect do
        post user_google_oauth2_omniauth_callback_path
      end.not_to change(User, :count)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('not permitted')
    end
  end

  describe 'identity collision' do
    let!(:user) do
      create(:user, account: account, email: 'taken@wabo.cc').tap do |u|
        u.update_columns(provider: 'google_oauth2', uid: 'original-uid')
      end
    end

    it 'rejects sign-in when the email is linked to a different Google uid' do
      stub_google_auth(email: 'taken@wabo.cc', uid: 'different-uid')

      post user_google_oauth2_omniauth_callback_path

      user.reload
      expect(user.uid).to eq('original-uid')
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe '2FA bypass' do
    let!(:user) do
      create(:user, account: account, email: '2fa@wabo.cc').tap do |u|
        u.update_columns(otp_required_for_login: true, otp_secret: User.generate_otp_secret)
      end
    end

    it 'signs the user in via Google without prompting for OTP' do
      stub_google_auth(email: '2fa@wabo.cc', uid: '2fa-uid')

      post user_google_oauth2_omniauth_callback_path

      expect(response).to redirect_to(root_path)
      get root_path
      expect(response).not_to redirect_to(mfa_setup_path)
    end
  end
end
