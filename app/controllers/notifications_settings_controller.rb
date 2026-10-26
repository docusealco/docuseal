# frozen_string_literal: true

class NotificationsSettingsController < ApplicationController
  before_action :load_bcc_config, only: :index
  before_action :load_reminder_config, only: :index
  authorize_resource :bcc_config, only: :index
  authorize_resource :reminder_config, only: :index

  before_action :build_account_config, only: :create
  authorize_resource :account_config, only: :create
  before_action :authorize_email_reminders!, only: :create

  def index; end

  def create
    if @account_config.value.present? ? @account_config.save : @account_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: I18n.t('changes_have_been_saved')
    else
      redirect_back fallback_location: settings_notifications_path, alert: I18n.t('unable_to_save')
    end
  end

  private

  def authorize_email_reminders!
    return unless Docuseal.multitenant?
    return if @account_config.key != AccountConfig::SUBMITTER_REMINDERS
    return if can?(:manage, :email_reminders)

    redirect_back fallback_location: settings_notifications_path, alert: I18n.t('unlock_with_docuseal_pro')
  end

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
    params.require(:account_config).permit(:key, :value, { value: {} }, { value: [] }).tap do |attrs|
      attrs[:key] = nil unless attrs[:key].in?([AccountConfig::BCC_EMAILS, AccountConfig::SUBMITTER_REMINDERS])
    end
  end
end
