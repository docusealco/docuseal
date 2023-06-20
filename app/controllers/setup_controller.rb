# frozen_string_literal: true

class SetupController < ApplicationController
  skip_before_action :maybe_redirect_to_setup
  skip_before_action :authenticate_user!

  before_action :redirect_to_root_if_signed, if: :signed_in?
  before_action :ensure_first_user_not_created!

  def index
    @account = Account.new(account_params)
    @user = @account.users.new(user_params)
    @encrypted_config = EncryptedConfig.new(account: @account, key: EncryptedConfig::APP_URL_KEY)
  end

  def create
    @account = Account.new(account_params)
    @user = @account.users.new(user_params)

    if @user.save
      encrypted_configs = [
        { key: EncryptedConfig::APP_URL_KEY, value: encrypted_config_params[:value] },
        { key: EncryptedConfig::ESIGN_CERTS_KEY, value: GenerateCertificate.call }
      ]
      @account.encrypted_configs.create!(encrypted_configs)

      sign_in(@user)

      redirect_to root_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def user_params
    return {} unless params[:user]

    params.require(:user).permit(:first_name, :last_name, :email, :password)
  end

  def account_params
    return {} unless params[:account]

    params.require(:account).permit(:name)
  end

  def encrypted_config_params
    return {} unless params[:encrypted_config]

    params.require(:encrypted_config).permit(:value)
  end

  def redirect_to_root_if_signed
    redirect_to root_path, notice: 'You are already signed in'
  end

  def ensure_first_user_not_created!
    redirect_to new_user_session_path, notice: 'Please sign in.' if User.exists?
  end
end
