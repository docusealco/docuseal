# frozen_string_literal: true

class SsoSettingsController < ApplicationController
  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index

  def index; end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: 'saml_configs')
  end
end
