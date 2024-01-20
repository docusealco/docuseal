# frozen_string_literal: true

class TestingApiSettingsController < ApplicationController
  def index
    authorize!(:manage, current_user.access_token)

    @webhook_config =
      current_account.encrypted_configs.find_or_initialize_by(key: EncryptedConfig::WEBHOOK_URL_KEY)

    authorize!(:manage, @webhook_config)
  end
end
