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
    AccountConfig::FORM_PREFILL_SIGNATURE_KEY,
    AccountConfig::ESIGNING_PREFERENCE_KEY,
    AccountConfig::FORM_WITH_CONFETTI_KEY,
    AccountConfig::DOWNLOAD_LINKS_AUTH_KEY,
    AccountConfig::FORCE_SSO_AUTH_KEY,
    AccountConfig::FLATTEN_RESULT_PDF_KEY,
    AccountConfig::ENFORCE_SIGNING_ORDER_KEY,
    AccountConfig::WITH_SIGNATURE_ID,
    AccountConfig::COMBINE_PDF_RESULT_KEY,
    AccountConfig::REQUIRE_SIGNING_REASON_KEY,
    AccountConfig::DOCUMENT_FILENAME_FORMAT_KEY
  ].freeze

  InvalidKey = Class.new(StandardError)

  def create
    @account_config.update!(account_config_params)

    head :ok
  end

  def destroy
    raise InvalidKey unless ALLOWED_KEYS.include?(@account_config.key)

    @account_config.destroy!

    redirect_back(fallback_location: root_path)
  end

  private

  def load_account_config
    raise InvalidKey unless ALLOWED_KEYS.include?(account_config_params[:key])

    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: account_config_params[:key])
  end

  def account_config_params
    params.required(:account_config).permit(:key, :value, { value: {} }, { value: [] }).tap do |attrs|
      attrs[:value] = attrs[:value] == '1' if attrs[:value].in?(%w[1 0])
    end
  end
end
