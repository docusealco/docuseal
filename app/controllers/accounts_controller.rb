# frozen_string_literal: true

class AccountsController < ApplicationController
  LOCALE_OPTIONS = {
    'en-US' => 'English (United States)',
    'en-GB' => 'English (United Kingdom)',
    'es-ES' => 'Spanish (Spain)',
    'pt-PT' => 'Portuguese (Portugal)',
    'de-DE' => 'German (Germany)'
  }.freeze

  def show; end

  def update
    current_account.update!(account_params)

    @encrypted_config = EncryptedConfig.find_or_initialize_by(account: current_account,
                                                              key: EncryptedConfig::APP_URL_KEY)
    @encrypted_config.update!(app_url_params)

    Docuseal.refresh_default_url_options!

    redirect_to settings_account_path, notice: 'Account information has been updated'
  rescue ActiveRecord::RecordInvalid
    render :show, status: :unprocessable_entity
  end

  private

  def account_params
    params.require(:account).permit(:name, :timezone, :locale)
  end

  def app_url_params
    params.require(:encrypted_config).permit(:value)
  end
end
