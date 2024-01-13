# frozen_string_literal: true

class PersonalizationSettingsController < ApplicationController
  def show
    authorize!(:read, AccountConfig)
  end

  def create
    account_config =
      current_account.account_configs.find_or_initialize_by(key: account_config_params[:key])

    authorize!(:create, account_config)

    account_config.update!(account_config_params)

    redirect_back(fallback_location: settings_personalization_path, notice: 'Settings have been saved.')
  end

  private

  def account_config_params
    attrs = params.require(:account_config).permit!

    attrs[:value]&.transform_values! do |value|
      if value.in?(%w[true false])
        value == 'true'
      else
        value
      end
    end

    attrs
  end
end
