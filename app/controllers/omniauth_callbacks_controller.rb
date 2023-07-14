# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = Users.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = I18n.t('devise.omniauth_callbacks.success', kind: 'Google')

      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_registration_path(oauth_callback: true, user: @user.slice(:email, :first_name, :last_name)),
                  notice: 'Please complete registration with Google auth'
    end
  end
end
