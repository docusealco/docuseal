# frozen_string_literal: true

class MfaSetupController < ApplicationController
  before_action do
    authorize!(:update, current_user)
  end

  before_action :set_provision_url, only: %i[show new]

  def show; end

  def new; end

  def edit; end

  def create
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.otp_required_for_login = true
      current_user.save!

      redirect_to settings_profile_index_path, notice: I18n.t('2fa_has_been_configured')
    else
      @provision_url = current_user.otp_provisioning_uri(current_user.email, issuer: Docuseal.product_name)

      @error_message = I18n.t('code_is_invalid')

      render turbo_stream: turbo_stream.replace(:mfa_form, partial: 'mfa_setup/form'), status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.update!(otp_required_for_login: false, otp_secret: nil)

      redirect_to settings_profile_index_path, notice: I18n.t('2fa_has_been_removed')
    else
      @error_message = I18n.t('code_is_invalid')

      render turbo_stream: turbo_stream.replace(:modal, template: 'mfa_setup/edit'), status: :unprocessable_entity
    end
  end

  private

  def set_provision_url
    return redirect_to root_path, alert: I18n.t('2fa_has_been_set_up_already') if current_user.otp_required_for_login

    current_user.otp_secret ||= User.generate_otp_secret

    current_user.save!

    @provision_url = current_user.otp_provisioning_uri(current_user.email, issuer: Docuseal.product_name)
  end
end
