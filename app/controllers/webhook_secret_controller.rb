# frozen_string_literal: true

class WebhookSecretController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, parent: false

  def index; end

  def create
    @encrypted_config.assign_attributes(value: {
      encrypted_config_params[:key] => encrypted_config_params[:value]
    }.compact_blank)

    @encrypted_config.value.present? ? @encrypted_config.save! : @encrypted_config.delete

    redirect_back(fallback_location: settings_webhooks_path, notice: 'Webhook Secret has been saved.')
  end

  private

  def load_encrypted_config
    @encrypted_config =
      current_account.encrypted_configs.find_or_initialize_by(key: EncryptedConfig::WEBHOOK_SECRET_KEY)
  end

  def encrypted_config_params
    params.require(:encrypted_config).permit(value: %i[key value]).fetch(:value, {})
  end
end
