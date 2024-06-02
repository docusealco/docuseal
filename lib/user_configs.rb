# frozen_string_literal: true

module UserConfigs
  module_function

  def load_signature(user)
    return if user.blank?

    uuid = user.user_configs.find_or_initialize_by(key: UserConfig::SIGNATURE_KEY).value

    ActiveStorage::Attachment.find_by(uuid:, record: user, name: 'signature') if uuid.present?
  end

  def load_initials(user)
    return if user.blank?

    uuid = user.user_configs.find_or_initialize_by(key: UserConfig::INITIALS_KEY).value

    ActiveStorage::Attachment.find_by(uuid:, record: user, name: 'initials') if uuid.present?
  end
end
