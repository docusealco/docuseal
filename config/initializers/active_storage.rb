# frozen_string_literal: true

ActiveSupport.on_load(:active_storage_attachment) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  has_many_attached :preview_images

  def signed_uuid
    @signed_uuid ||= ApplicationRecord.signed_id_verifier.generate(uuid, expires_in: 6.hours)
  end

  def preview_image_url
    first_page = preview_images.joins(:blob).find_by(blob: { filename: '0.jpg' })

    return unless first_page

    Rails.application.routes.url_helpers.rails_storage_proxy_url(first_page, **Docuseal.default_url_options)
  end
end

ActiveSupport.on_load(:active_storage_blob) do
  attribute :uuid, :string, default: -> { SecureRandom.uuid }

  def uuid
    super || begin
      new_uuid = SecureRandom.uuid
      update_columns(uuid: new_uuid)
      new_uuid
    end
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
    next if current_user
    next if Submitter.find_signed(cookies[:submitter_sid])

    head :forbidden
  end

  LoadActiveStorageConfigs.call
rescue StandardError => e
  Rails.logger.error(e)

  nil
end
