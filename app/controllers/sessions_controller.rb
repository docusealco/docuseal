# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  def create
    if Docuseal.multitenant? && !User.exists?(email: sign_in_params[:email])
      return redirect_to new_registration_path(sign_up: true, user: sign_in_params.slice(:email)),
                         notice: 'Create a new account'
    end

    super
  end

  private

  def after_sign_in_path_for(...)
    if params[:redir].present?
      return console_redirect_index_path(redir: params[:redir]) if params[:redir].starts_with?(Docuseal::CONSOLE_URL)

      return params[:redir]
    end

    super
  end

  def require_no_authentication
    super

    flash.clear
  end
end
