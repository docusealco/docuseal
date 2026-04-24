# frozen_string_literal: true

class AccountLogoController < ApplicationController
  before_action :load_account
  authorize_resource :account

  def create
    file = params[:logo]

    return redirect_to settings_personalization_path, alert: I18n.t('unable_to_upload_logo') if file.blank?

    current_account.logo.attach(file)

    redirect_to settings_personalization_path, notice: I18n.t('logo_has_been_saved')
  end

  def destroy
    current_account.logo.purge

    redirect_to settings_personalization_path, notice: I18n.t('logo_has_been_removed')
  end

  private

  def load_account
    @account = current_account
  end
end
