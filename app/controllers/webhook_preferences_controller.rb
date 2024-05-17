# frozen_string_literal: true

class WebhookPreferencesController < ApplicationController
  EVENTS = %w[
    form.viewed
    form.started
    form.completed
    template.created
    template.updated
    submission.created
    submission.archived
  ].freeze

  before_action :load_account_config
  authorize_resource :account_config, parent: false

  def create
    @account_config.value[account_config_params[:event]] = account_config_params[:value] == '1'

    @account_config.save!

    head :ok
  end

  private

  def load_account_config
    @account_config =
      current_account.account_configs.find_or_initialize_by(key: AccountConfig::WEBHOOK_PREFERENCES_KEY)
    @account_config.value ||= {}
  end

  def account_config_params
    params.permit(:event, :value)
  end
end
