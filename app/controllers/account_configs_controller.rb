# frozen_string_literal: true

class AccountConfigsController < ApplicationController
  before_action :load_account_config, only: :create
  authorize_resource :account_config, only: :create

  load_and_authorize_resource :account_config, only: :destroy

  ALLOWED_KEYS = [
    AccountConfig::ALLOW_TYPED_SIGNATURE,
    AccountConfig::FORCE_MFA,
    AccountConfig::ALLOW_TO_RESUBMIT,
    AccountConfig::ALLOW_TO_DECLINE_KEY,
    AccountConfig::ALLOW_TO_DELEGATE_KEY,
    AccountConfig::FORM_PREFILL_SIGNATURE_KEY,
    AccountConfig::ESIGNING_PREFERENCE_KEY,
    AccountConfig::FORM_WITH_CONFETTI_KEY,
    AccountConfig::DOWNLOAD_LINKS_AUTH_KEY,
    AccountConfig::DOWNLOAD_LINKS_EXPIRE_KEY,
    AccountConfig::FORCE_SSO_AUTH_KEY,
    AccountConfig::FLATTEN_RESULT_PDF_KEY,
    AccountConfig::ENFORCE_SIGNING_ORDER_KEY,
    AccountConfig::WITH_FILE_LINKS_KEY,
    AccountConfig::WITH_SIGNATURE_ID,
    AccountConfig::COMBINE_PDF_RESULT_KEY,
    AccountConfig::REQUIRE_SIGNING_REASON_KEY,
    AccountConfig::DOCUMENT_FILENAME_FORMAT_KEY,
    AccountConfig::ENABLE_MCP_KEY,
    AccountConfig::EMBED_ALLOWED_ORIGINS_KEY
  ].freeze

  InvalidKey = Class.new(StandardError)

  def create
    @account_config.update!(account_config_params)

    head :ok
  end

  def destroy
    raise InvalidKey unless allowed_keys.include?(@account_config.key)

    @account_config.destroy!

    redirect_back(fallback_location: root_path)
  end

  private

  def allowed_keys
    ALLOWED_KEYS
  end

  def load_account_config
    raise InvalidKey unless allowed_keys.include?(account_config_params[:key])

    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: account_config_params[:key])
  end

  def account_config_params
    params.required(:account_config).permit(:key, :value, { value: {} }, { value: [] }).tap do |attrs|
      attrs[:value] = attrs[:value] == '1' if attrs[:value].in?(%w[1 0])
      attrs[:value] = normalize_origins(attrs[:value]) if attrs[:key] == AccountConfig::EMBED_ALLOWED_ORIGINS_KEY
    end
  end

  def normalize_origins(value)
    value.to_s.split(/[\s,]+/).filter_map do |origin|
      uri = Addressable::URI.parse(origin.strip)

      next unless uri.scheme.in?(%w[http https]) && uri.host.present?

      uri.path = nil
      uri.query = nil
      uri.fragment = nil
      uri.to_s.delete_suffix('/')
    rescue Addressable::URI::InvalidURIError
      nil
    end.uniq
  end
end
