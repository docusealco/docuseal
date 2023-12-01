# frozen_string_literal: true

class MfaForceController < ApplicationController
  before_action :load_account_config
  authorize_resource :account_config

  def create
    @account_config.update!(value: !@account_config.value)

    redirect_back fallback_location: settings_users_path,
                  notice: "Force 2FA has been #{@account_config.value ? 'enabled' : 'disabled'}."
  end

  private

  def load_account_config
    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: AccountConfig::FORCE_MFA)
  end
end
