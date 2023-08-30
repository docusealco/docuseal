# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :require_no_authentication, only: [:show]
  prepend_before_action :maybe_redirect_if_signed_in, only: [:show]

  def show; end

  def create
    super

    Accounts.create_default_template(resource.account) if resource.account.persisted?
  end

  private

  def after_sign_up_path_for(...)
    if params[:redir].present?
      return console_redirect_index_path(redir: params[:redir]) if params[:redir].starts_with?(Docuseal::CONSOLE_URL)

      return params[:redir]
    end

    super
  end

  def maybe_redirect_if_signed_in
    return unless signed_in?
    return if params[:redir].blank?

    redirect_to after_sign_up_path_for(current_user), allow_other_host: true
  end

  def require_no_authentication
    super

    flash.clear
  end

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
