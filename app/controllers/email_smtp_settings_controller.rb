# frozen_string_literal: true

class EmailSmtpSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: :create

  def index; end

  def create
    if @encrypted_config.update(email_configs)
      SettingsMailer.smtp_successful_setup(@encrypted_config.value['from_email']).deliver_now!

      redirect_to settings_email_index_path, notice: 'Changes have been saved'
    else
      render :index, status: :unprocessable_entity
    end
  rescue StandardError => e
    flash[:alert] = e.message

    render :index, status: :unprocessable_entity
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::EMAIL_SMTP_KEY)
  end

  def email_configs
    params.require(:encrypted_config).permit(value: {}).tap do |e|
      e[:value].compact_blank!
    end
  end
end
