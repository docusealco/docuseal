# frozen_string_literal: true

class ProfileController < ApplicationController
  before_action :load_encrypted_config, only: %i[index update_app_url]

  def index; end

  def update_contact
    if current_user.update(contact_params)
      redirect_to settings_profile_index_path, notice: 'Contact information successfully updated'
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update_password
    if current_user.update(password_params)
      bypass_sign_in(current_user)
      redirect_to settings_profile_index_path, notice: 'Password successfully changed'
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update_app_url
    if @encrypted_config.update(app_url_params)
      Docuseal.refresh_default_url_options!

      redirect_to settings_profile_index_path, notice: 'App URL successfully changed'
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::APP_URL_KEY)
  end

  def contact_params
    params.require(:user).permit(:first_name, :last_name, :email, account_attributes: %i[name])
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def app_url_params
    params.require(:encrypted_config).permit(:value)
  end
end
