# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  def create
    if Docuseal.multitenant? && !User.exists?(email: sign_in_params[:email])
      return redirect_to new_registration_path(sign_up: true, user: sign_in_params.slice(:email)),
                         notice: 'Create a new account'
    end

    super
  end
end
