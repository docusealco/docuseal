# frozen_string_literal: true

class NotificationsSettingsController < ApplicationController
  before_action :load_bcc_config, only: :index
  before_action :load_reminder_config, only: :index
  before_action :load_pending_reminders, only: :index
  authorize_resource :bcc_config, only: :index
  authorize_resource :reminder_config, only: :index

  before_action :build_account_config, only: :create
  authorize_resource :account_config, only: :create

  def index; end

  def create
    if @account_config.value.present? ? @account_config.save : @account_config.delete
      redirect_back fallback_location: settings_notifications_path, notice: I18n.t('changes_have_been_saved')
    else
      redirect_back fallback_location: settings_notifications_path, alert: I18n.t('unable_to_save')
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

  def load_pending_reminders
    @pending_reminders = []
    return unless @reminder_config&.value.is_a?(Hash)

    submitters = Submitter
      .joins(:submission)
      .where(account_id: current_account.id)
      .where.not(sent_at: nil)
      .where(completed_at: nil, declined_at: nil)
      .where.not(email: [nil, ''])
      .where(submissions: { archived_at: nil })
      .includes(:submission, :template, :submission_events)
      .limit(50)

    submitters.each do |submitter|
      next if submitter.template&.archived_at?

      next_at = SubmitterReminders.next_reminder_at(submitter, @reminder_config)
      next unless next_at

      last_reminder = submitter.submission_events
                               .select { |e| e.event_type.in?(%w[send_reminder_email skip_reminder_email]) }
                               .max_by(&:created_at)

      @pending_reminders << {
        submitter: submitter,
        next_at: next_at,
        last_sent_at: last_reminder&.created_at
      }
    end

    @pending_reminders.sort_by! { |r| r[:next_at] }
  end

  def email_config_params
    params.require(:account_config).permit(:key, :value, { value: {} }, { value: [] }).tap do |attrs|
      attrs[:key] = nil unless attrs[:key].in?([AccountConfig::BCC_EMAILS, AccountConfig::SUBMITTER_REMINDERS])
    end
  end
end
