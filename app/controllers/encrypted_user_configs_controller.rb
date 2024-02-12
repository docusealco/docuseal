# frozen_string_literal: true

class EncryptedUserConfigsController < ApplicationController
  load_and_authorize_resource :encrypted_user_config

  def destroy
    @encrypted_user_config.destroy!

    redirect_back(fallback_location: root_path)
  end
end
