# frozen_string_literal: true

class WebhookSettingsController < ApplicationController
  before_action :load_webhook_url
  authorize_resource :webhook_url, parent: false

  def show; end

  def create
    @webhook_url.assign_attributes(webhook_params)

    @webhook_url.url.present? ? @webhook_url.save! : @webhook_url.delete

    redirect_back(fallback_location: settings_webhooks_path, notice: I18n.t('webhook_url_has_been_saved'))
  end

  def update
    submitter = current_account.submitters.where.not(completed_at: nil).order(:id).last

    SendFormCompletedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                     'webhook_url_id' => @webhook_url.id)

    redirect_back(fallback_location: settings_webhooks_path, notice: I18n.t('webhook_request_has_been_sent'))
  end

  private

  def load_webhook_url
    @webhook_url = current_account.webhook_urls.first_or_initialize
  end

  def webhook_params
    params.require(:webhook_url).permit(:url)
  end
end
