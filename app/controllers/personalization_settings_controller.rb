# frozen_string_literal: true

class PersonalizationSettingsController < ApplicationController
  def show; end

  def create
    account_config =
      current_account.account_configs.find_or_initialize_by(key: encrypted_config_params[:key])

    account_config.update!(encrypted_config_params)

    redirect_back(fallback_location: settings_personalization_path, notice: 'Settings have been saved.')
  end

  private

  def encrypted_config_params
    params.require(:account_config).permit!
  end
end
