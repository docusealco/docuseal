# frozen_string_literal: true

class ProfileController < ApplicationController
  def update_contact
    if current_user.update(contact_params)
      redirect_to contact_settings_profile_index_path, notice: 'Contact information successfully updated'
    else
      render :contact, status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to password_settings_profile_index_path, notice: 'Password successfully changed'
    else
      render :password, status: :unprocessable_entity
    end
  end

  def update_email
    if current_user.update_with_password(email_params)
      redirect_to email_settings_profile_index_path, notice: 'Email successfully updated. Please check your new email for confirmation instructions.'
    else
      render :email, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:user).permit(:first_name, :last_name, account_attributes: %i[name])
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def email_params
    params.require(:user).permit(:current_password, :email)
  end
end
