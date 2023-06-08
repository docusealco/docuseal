# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_attachment) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  has_many_attached :preview_images
end

Rails.configuration.to_prepare do
  ActiveStorage::DiskController.after_action do
    response.set_header('Cache-Control', 'public, max-age=31536000') if action_name == 'show'
  end

  LoadActiveStorageConfigs.call
rescue StandardError => e
  Rails.logger.debug(e)

  nil
end
