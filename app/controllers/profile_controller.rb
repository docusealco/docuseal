# frozen_string_literal: true

class ProfileController < ApplicationController
  before_action do
    authorize!(:manage, current_user)
  end

  def index; end

  def update_contact
    if current_user.update(contact_params)
      redirect_to settings_profile_index_path, notice: 'Contact information has been updated'
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update(password_params)
      bypass_sign_in(current_user)
      redirect_to settings_profile_index_path, notice: 'Password has been changed'
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
