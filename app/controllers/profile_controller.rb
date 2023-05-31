# frozen_string_literal: true

class ProfileController < ApplicationController
  def index
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to settings_profile_path, notice: 'Profile updated'
    else
      render :index
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name)
  end
end
