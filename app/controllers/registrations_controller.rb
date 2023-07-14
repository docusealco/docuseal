# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: [:show]

  def show; end

  def create
    super

    Accounts.create_default_template(resource.account) if resource.account.persisted?
  end

  private

  def build_resource(_hash = {})
    account = Account.new(account_params)
    account.timezone = Accounts.normalize_timezone(account.timezone)

    self.resource = account.users.new(user_params)

    account.name ||= "#{resource.full_name}'s Company" if params[:action] == 'create'
  end

  def user_params
    return {} if params[:user].blank?

    params.require(:user).permit(:first_name, :last_name, :email, :password).compact_blank.tap do |attrs|
      attrs[:password] ||= SecureRandom.hex if params[:action] == 'create'
    end
  end

  def account_params
    return {} if params[:account].blank?

    params.require(:account).permit(:name, :timezone).compact_blank
  end
end
