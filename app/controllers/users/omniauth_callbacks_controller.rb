# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: [:clerk_oidc]

    def clerk_oidc
      user = User.from_clerk_oidc(request.env['omniauth.auth'])

      if user&.persisted?
        sign_in_and_redirect(user, event: :authentication)
        set_flash_message(:notice, :success, kind: 'Clerk') if is_navigational_format?
      else
        flash[:alert] = I18n.t('clerk_oidc_login_not_allowed',
                               default: 'Sign-in not permitted for this account.')
        redirect_to new_user_session_path
      end
    end

    def failure
      flash[:alert] = I18n.t('clerk_oidc_login_failed', default: 'Clerk sign-in failed. Please try again.')
      redirect_to new_user_session_path
    end
  end
end
