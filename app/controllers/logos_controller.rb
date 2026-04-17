class LogosController < ApplicationController
  def create
    authorize! :update, current_account

    current_account.logo.attach(logo_params[:logo])

    redirect_back fallback_location: settings_personalization_path,
                  notice: I18n.t('settings_have_been_saved')
  end

  def destroy
    authorize! :update, current_account

    current_account.logo.purge

    redirect_back fallback_location: settings_personalization_path,
                  notice: I18n.t('settings_have_been_saved')
  end

  private

  def logo_params
    params.require(:account_logo).permit(:logo)
  end
end
