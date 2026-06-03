# frozen_string_literal: true

class SmsSettingsController < ApplicationController
  PASSWORD_FIELDS = %w[basic_auth_token twilio_auth_token voipms_api_password signalwire_api_token].freeze
  private_constant :PASSWORD_FIELDS

  before_action :load_encrypted_config
  authorize_resource :encrypted_config, only: :index
  authorize_resource :encrypted_config, parent: false, only: %i[create test_message]

  def index; end

  def create
    new_value = build_sms_value

    if @encrypted_config.update(value: new_value)
      redirect_to settings_sms_path, notice: I18n.t('changes_have_been_saved')
    else
      render :index, status: :unprocessable_content
    end
  rescue StandardError => e
    flash[:alert] = e.message
    render :index, status: :unprocessable_content
  end

  def test_message
    to = params[:phone].to_s.strip
    if to.blank?
      flash[:alert] = 'Enter a phone number to test against.'
      return redirect_to(settings_sms_path)
    end

    Sms.send_message(account: current_account,
                     to: to,
                     text: "Test SMS from #{Wabosign.branded_product_name(current_account)}.")

    redirect_to settings_sms_path, notice: "Test SMS dispatched to #{to}."
  rescue Sms::Error => e
    redirect_to settings_sms_path, alert: "Test failed: #{e.message}"
  rescue StandardError => e
    redirect_to settings_sms_path, alert: "Unexpected error: #{e.message}"
  end

  private

  def load_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account, key: EncryptedConfig::SMS_CONFIGS_KEY)
  end

  def build_sms_value
    permitted = params.require(:encrypted_config).require(:value).permit(
      :enabled,
      :provider,
      :basic_auth_token,
      :from_number,
      :delivery_webhook_url,
      :twilio_account_sid,
      :twilio_auth_token,
      :twilio_from,
      :voipms_api_username,
      :voipms_api_password,
      :voipms_did,
      :signalwire_space_url,
      :signalwire_project_id,
      :signalwire_api_token,
      :signalwire_from
    ).to_h

    existing = @encrypted_config.value.is_a?(Hash) ? @encrypted_config.value : {}

    PASSWORD_FIELDS.each do |field|
      permitted[field] = existing[field] if permitted[field].blank? && existing[field].present?
    end

    permitted
  end
end
