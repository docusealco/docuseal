# frozen_string_literal: true

class AccountConfigsController < ApplicationController
  before_action :load_account_config
  authorize_resource :account_config

  ALLOWED_KEYS = [
    AccountConfig::ALLOW_TYPED_SIGNATURE,
    AccountConfig::FORCE_MFA,
    AccountConfig::ALLOW_TO_RESUBMIT,
    AccountConfig::FORM_PREFILL_SIGNATURE_KEY,
    AccountConfig::ESIGNING_PREFERENCE_KEY,
    AccountConfig::FORM_WITH_CONFETTI_KEY,
    AccountConfig::DOWNLOAD_LINKS_AUTH_KEY,
    AccountConfig::FORCE_SSO_AUTH_KEY,
    AccountConfig::FLATTEN_RESULT_PDF_KEY,
    AccountConfig::WITH_SIGNATURE_ID
  ].freeze

  InvalidKey = Class.new(StandardError)

  def create
    @account_config.update!(account_config_params)

    head :ok
  end

  private

  def load_account_config
    raise InvalidKey unless ALLOWED_KEYS.include?(account_config_params[:key])

    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: account_config_params[:key])
  end

  def account_config_params
    params.required(:account_config).permit!.tap do |attrs|
      attrs[:value] = attrs[:value] == '1' if attrs[:value].in?(%w[1 0])
    end
  end
end
