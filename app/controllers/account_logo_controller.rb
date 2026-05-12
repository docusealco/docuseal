# frozen_string_literal: true

class AccountLogoController < ApplicationController
  before_action :authorize_account_config

  def create
    file = params[:file]

    return redirect_to settings_personalization_path, alert: I18n.t('unable_to_save') if file.blank?

    current_account.logo.attach(file)

    redirect_to settings_personalization_path, notice: I18n.t('settings_have_been_saved')
  end

  def destroy
    current_account.logo.purge

    redirect_to settings_personalization_path, notice: I18n.t('settings_have_been_saved')
  end

  private

  def authorize_account_config
    authorize!(:create, AccountConfig)
  end
end
