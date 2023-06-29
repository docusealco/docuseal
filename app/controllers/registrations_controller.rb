# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  private

  def build_resource(_hash = {})
    account = Account.new(account_params)
    account.timezone = Accounts.normalize_timezone(account.timezone)

    self.resource = account.users.new(user_params)
  end

  def user_params
    return {} if params[:user].blank?

    params.require(:user).permit(:first_name, :last_name, :email, :password)
  end

  def account_params
    return {} if params[:account].blank?

    params.require(:account).permit(:name, :timezone)
  end
end
