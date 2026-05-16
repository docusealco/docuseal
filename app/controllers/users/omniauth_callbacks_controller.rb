# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, raise: false

    def google_oauth2
      user = User.from_google_omniauth(request.env['omniauth.auth'])

      if user&.persisted? && user.active_for_authentication?
        # Trust Google's MFA: bypass the WaboSign OTP gate for this session.
        session[:bypass_otp_for_sso] = true
        sign_in(user, event: :authentication)
        set_flash_message(:notice, :signed_in, kind: 'Google') if is_flashing_format?
        redirect_to after_sign_in_path_for(user)
      else
        flash[:alert] = 'Google sign-in failed: this Google account is not permitted to sign in.'
        redirect_to new_user_session_path
      end
    end

    def failure
      flash[:alert] = "Google sign-in failed: #{failure_message}"
      redirect_to new_user_session_path
    end
  end
end
