# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_attachment) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  has_many_attached :preview_images

  def signed_uuid
    @signed_uuid ||= ApplicationRecord.signed_id_verifier.generate(uuid, expires_in: 6.hours, purpose: :attachment)
  end
end

ActiveSupport.on_load(:active_storage_blob) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  def self.proxy_url(blob, expires_at: nil)
    Rails.application.routes.url_helpers.blobs_proxy_url(
      signed_uuid: blob.signed_uuid(expires_at:), filename: blob.filename,
      **Docuseal.default_url_options
    )
  end

  def uuid
    super || begin
      new_uuid = SecureRandom.uuid
      update_columns(uuid: new_uuid)
      new_uuid
    end
  end

  def signed_uuid(expires_at: nil)
    expires_at = expires_at.to_i if expires_at

    ApplicationRecord.signed_id_verifier.generate([uuid, 'blob', expires_at].compact)
  end

  def delete
    service.delete(key)
  end
end

ActiveStorage::LogSubscriber.detach_from(:active_storage) if Rails.env.production?

Rails.configuration.to_prepare do
  ActiveStorage::DiskController.after_action do
    response.set_header('Cache-Control', 'public, max-age=31536000') if action_name == 'show'
  end

  ActiveStorage::Blobs::ProxyController.before_action do
    response.set_header('Access-Control-Allow-Origin', '*')
    response.set_header('Access-Control-Allow-Methods', 'GET')
    response.set_header('Access-Control-Allow-Headers', '*')
    response.set_header('Access-Control-Max-Age', '1728000')
  end

  ActiveStorage::Blobs::RedirectController.before_action do
    response.set_header('Access-Control-Allow-Origin', '*')
    response.set_header('Access-Control-Allow-Methods', 'GET')
    response.set_header('Access-Control-Allow-Headers', '*')
    response.set_header('Access-Control-Max-Age', '1728000')
  end

  ActiveStorage::DirectUploadsController.before_action do
    head :forbidden
  end

  LoadActiveStorageConfigs.call
rescue StandardError => e
  Rails.logger.error(e) unless Rails.env.production?

  nil
end
