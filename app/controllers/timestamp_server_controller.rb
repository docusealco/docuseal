# frozen_string_literal: true

class TimestampServerController < ApplicationController
  HASH_ALGORITHM = 'SHA256'

  before_action :build_encrypted_config
  authorize_resource :encrypted_config

  TimestampError = Class.new(StandardError)

  def create
    return head :not_found if Docuseal.multitenant?

    test_timeserver_url(@encrypted_config.value) if @encrypted_config.value.present?

    if @encrypted_config.value.present? ? @encrypted_config.save : @encrypted_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: 'Changes have been saved'
    else
      redirect_back fallback_location: settings_notifications_path, alert: 'Unable to save'
    end
  rescue SocketError, TimestampError, OpenSSL::Timestamp::TimestampError
    redirect_back fallback_location: settings_notifications_path, alert: 'Invalid Timeserver'
  end

  private

  def test_timeserver_url(url)
    req = OpenSSL::Timestamp::Request.new
    req.algorithm = HASH_ALGORITHM
    req.message_imprint = OpenSSL::Digest.digest(HASH_ALGORITHM, 'test')

    uri = Addressable::URI.parse(url)

    conn = Faraday.new(uri.origin) do |c|
      c.basic_auth(uri.user, uri.password) if uri.password.present?
    end

    response = conn.post(uri.path, req.to_der,
                         'content-type' => 'application/timestamp-query')

    raise TimestampError if response.status != 200 || response.body.blank?

    response
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
