# frozen_string_literal: true

class MfaSetupController < ApplicationController
  before_action do
    authorize!(:update, current_user)
  end

  def new
    current_user.otp_secret ||= User.generate_otp_secret

    current_user.save!

    @provision_url = current_user.otp_provisioning_uri(current_user.email, issuer: Docuseal::PRODUCT_NAME)
  end

  def edit; end

  def create
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.otp_required_for_login = true
      current_user.save!

      redirect_to settings_profile_index_path, notice: '2FA has been configured'
    else
      @provision_url = current_user.otp_provisioning_uri(current_user.email, issuer: Docuseal::PRODUCT_NAME)

      @error_message = 'Code is invalid'

      render turbo_stream: turbo_stream.replace(:modal, template: 'mfa_setup/new'), status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.update!(otp_required_for_login: false, otp_secret: nil)

      redirect_to settings_profile_index_path, notice: '2FA has been removed'
    else
      @error_message = 'Code is invalid'

      render turbo_stream: turbo_stream.replace(:modal, template: 'mfa_setup/edit'), status: :unprocessable_entity
    end
  end
end
