# frozen_string_literal: true

class LogoSettingsController < ApplicationController
  before_action :require_admin!

  def update
    authorize!(:manage, current_account)

    if params[:remove_logo] == '1'
      current_account.logo.purge
    elsif params[:logo].present?
      current_account.logo.attach(params[:logo])
    end

    redirect_to settings_personalization_path, notice: t('settings_have_been_saved')
  end
end
