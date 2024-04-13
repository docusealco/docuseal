# frozen_string_literal: true

class NotificationsSettingsController < ApplicationController
  before_action :load_bcc_config, only: :index
  before_action :load_reminder_config, only: :index
  authorize_resource :bcc_config, only: :index
  authorize_resource :reminder_config, only: :index

  before_action :build_account_config, only: :create
  authorize_resource :account_config, only: :create

  def index; end

  def create
    if @account_config.value.present? ? @account_config.save : @account_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: 'Changes have been saved'
    else
      redirect_back fallback_location: settings_notifications_path, alert: 'Unable to save'
    end
  end

  private

  def build_account_config
    @account_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: email_config_params[:key])

    @account_config.assign_attributes(email_config_params)
  end

  def load_bcc_config
    @bcc_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: AccountConfig::BCC_EMAILS)
  end

  def load_reminder_config
    @reminder_config =
      AccountConfig.find_or_initialize_by(account: current_account, key: AccountConfig::SUBMITTER_REMINDERS)
  end

  def email_config_params
    params.require(:account_config).permit!.tap do |attrs|
      attrs[:key] = nil unless attrs[:key].in?([AccountConfig::BCC_EMAILS, AccountConfig::SUBMITTER_REMINDERS])
    end
  end
end
