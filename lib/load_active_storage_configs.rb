# frozen_string_literal: true

module LoadActiveStorageConfigs
  STORAGE_YML_PATH = Rails.root.join('config/storage.yml')
  IS_ENV_CONFIGURED =
    ENV['S3_ATTACHMENTS_BUCKET'].present? || ENV['GCS_BUCKET'].present? || ENV['AZURE_CONTAINER'].present?

  module_function

  def call
    reload unless loaded?
  end

  def loaded?
    @loaded
  end

  def reload
    return if Docuseal.multitenant?
    return if IS_ENV_CONFIGURED
    return if Rails.env.test?
    return if Rails.env.development?

    encrypted_config = EncryptedConfig.find_by(key: EncryptedConfig::FILES_STORAGE_KEY)

    return unless encrypted_config

    service, configs = encrypted_config.value.values_at('service', 'configs')

    service_configurations = ActiveSupport::ConfigurationFile.parse(STORAGE_YML_PATH)
    service_configurations[service].merge!(configs) if configs.present?
    service_configurations[service][:force_path_style] = true if configs&.dig('endpoint').present?

    if service == 'google'
      service_configurations[service][:credentials] = JSON.parse(configs.fetch('credentials', '{}'))
    end

    ActiveStorage::Blob.services = ActiveStorage::Service::Registry.new(service_configurations)
    ActiveStorage::Blob.service = ActiveStorage::Blob.services.fetch(service.to_sym)
  ensure
    @loaded = true
  end
end
