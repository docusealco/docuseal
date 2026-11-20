# frozen_string_literal: true

class TimestampServerController < ApplicationController
  HASH_ALGORITHM = 'SHA256'
  HEADER_NAME_REGEXP = /\A[\w-]+\z/

  before_action :build_encrypted_config
  authorize_resource :encrypted_config

  TimestampError = Class.new(StandardError)

  def create
    return head :not_found if Docuseal.multitenant?

    url = encrypted_config_params[:url].to_s.strip
    headers = parse_headers(encrypted_config_params[:headers])

    test_timeserver_url(url, headers) if url.present?

    @encrypted_config.value = { 'url' => url, 'headers' => headers }.compact_blank

    if url.present? ? @encrypted_config.save : @encrypted_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: I18n.t('changes_have_been_saved')
    else
      redirect_back fallback_location: settings_notifications_path, alert: I18n.t('unable_to_save')
    end
  rescue SocketError, TimestampError, OpenSSL::Timestamp::TimestampError
    redirect_back fallback_location: settings_notifications_path, alert: t('invalid_timeserver')
  end

  private

  def test_timeserver_url(url, headers = {})
    req = OpenSSL::Timestamp::Request.new
    req.algorithm = HASH_ALGORITHM
    req.message_imprint = OpenSSL::Digest.digest(HASH_ALGORITHM, 'test')

    uri = Addressable::URI.parse(url)

    conn = Faraday.new(uri.origin) do |c|
      c.request :authorization, :basic, uri.user, uri.password if uri.password.present?
    end

    response = conn.post(uri.path, req.to_der,
                         { 'content-type' => 'application/timestamp-query' }.merge(headers))

    raise TimestampError if response.status != 200 || response.body.blank?

    response
  end

  # "Name: value" lines, one per header, matching the webhook secret header format
  def parse_headers(raw)
    raw.to_s.each_line.with_object({}) do |line, acc|
      name, value = line.split(':', 2)

      next if name.blank? || value.blank?

      name = name.strip
      value = value.strip

      acc[name] = value if HEADER_NAME_REGEXP.match?(name)
    end
  end

  def load_encrypted_config
    @encrypted_config
  end

  def build_encrypted_config
    @encrypted_config =
      EncryptedConfig.find_or_initialize_by(account: current_account,
                                            key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)
  end

  def encrypted_config_params
    params.require(:encrypted_config).permit(:url, :headers)
  end
end
