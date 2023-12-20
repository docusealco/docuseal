# frozen_string_literal: true

class TimestampServerController < ApplicationController
  before_action :build_encrypted_config
  authorize_resource :encrypted_config

  def create
    return head :not_found if Docuseal.multitenant?

    test_timeserver_url(@encrypted_config.value) if @encrypted_config.value.present?

    if @encrypted_config.value.present? ? @encrypted_config.save : @encrypted_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: 'Changes have been saved'
    else
      redirect_back fallback_location: settings_notifications_path, alert: 'Unable to save'
    end
  rescue HexaPDF::Error, SocketError, Submissions::TimestampHandler::TimestampError, OpenSSL::Timestamp::TimestampError
    redirect_back fallback_location: settings_notifications_path, alert: 'Invalid Timeserver'
  end

  private

  def test_timeserver_url(url)
    pdf = HexaPDF::Document.new
    pdf.pages.add

    pkcs = Accounts.load_signing_pkcs(current_account)

    pdf.sign(StringIO.new,
             reason: 'Test',
             certificate: pkcs.certificate,
             key: pkcs.key,
             signature_size: 10_000,
             certificate_chain: pkcs.ca_certs || [],
             timestamp_handler: Submissions::TimestampHandler.new(tsa_url: url))
  end

  def load_encrypted_config
    @encrypted_config
  end

  def build_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account,
                                            key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)

    @encrypted_config.assign_attributes(encrypted_config_params)
  end

  def encrypted_config_params
    params.require(:encrypted_config).permit(:value)
  end
end
