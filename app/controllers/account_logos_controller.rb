# frozen_string_literal: true

class AccountLogosController < ApplicationController
  before_action :load_account
  authorize_resource :account

  def update
    file = params[:file]

    return redirect_to settings_personalization_path, alert: I18n.t('file_is_missing') if file.blank?

    @account.logo.attach(
      io: file.open,
      filename: file.original_filename,
      content_type: file.content_type
    )

    redirect_to settings_personalization_path, notice: I18n.t('logo_has_been_uploaded')
  end

  def destroy
    @account.logo.purge

    redirect_to settings_personalization_path, notice: I18n.t('logo_has_been_uploaded')
  end

  private

  def load_account
    @account = current_account
  end
end
