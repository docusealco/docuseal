# frozen_string_literal: true

class StorageSettingsController < ApplicationController
  ENV_STORAGE_SERVICES = {
    'S3_ATTACHMENTS_BUCKET' => ['aws_s3', 'AWS S3'],
    'GCS_BUCKET' => ['google', 'GCP'],
    'AZURE_CONTAINER' => ['azure', 'Azure']
  }.freeze

  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: :create

  def index; end

  def create
    if @env_storage_service.present?
      redirect_to settings_storage_index_path, alert: I18n.t('storage_settings_are_managed_by_environment_variables')

      return
    end

    if @encrypted_config.update(storage_configs)
      LoadActiveStorageConfigs.reload

      redirect_to settings_storage_index_path, notice: I18n.t('changes_have_been_saved')
    else
      render :index, status: :unprocessable_content
    end
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::FILES_STORAGE_KEY)
    @env_storage_env_var, @env_storage_service, @env_storage_service_label = env_storage_service
    @storage_value =
      if @env_storage_service.present?
        { 'service' => @env_storage_service }
      else
        @encrypted_config.value || { 'service' => 'disk' }
      end
  end

  def storage_configs
    params.require(:encrypted_config).permit(value: {}).tap do |e|
      e[:value].compact_blank!

      e.dig(:value, :configs)&.compact_blank!
    end
  end

  def env_storage_service
    ENV_STORAGE_SERVICES.each do |env_var, (service, label)|
      return [env_var, service, label] if ENV[env_var].present?
    end

    nil
  end
end
