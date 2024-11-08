# frozen_string_literal: true

class WebhookSettingsController < ApplicationController
  before_action :load_webhook_url, only: %i[show update destroy]
  authorize_resource :webhook_url, parent: false

  def index
    @webhook_urls = current_account.webhook_urls.order(id: :desc)
    @webhook_url = @webhook_urls.first_or_initialize

    render @webhook_urls.size > 1 ? 'index' : 'show'
  end

  def show; end

  def new
    @webhook_url = current_account.webhook_urls.build
  end

  def create
    @webhook_url = current_account.webhook_urls.build(create_webhook_params)

    @webhook_url.save!

    redirect_to settings_webhooks_path, notice: I18n.t('webhook_url_has_been_saved')
  end

  def update
    @webhook_url.update!(update_webhook_params)

    redirect_to settings_webhook_path(@webhook_url), notice: I18n.t('webhook_url_has_been_updated')
  end

  def destroy
    @webhook_url.delete

    redirect_to settings_webhooks_path, notice: I18n.t('webhook_url_has_been_deleted')
  end

  def resend
    submitter = current_account.submitters.where.not(completed_at: nil).order(:id).last
    webhook = current_account.webhook_urls
                             .where(Arel::Table.new(:webhook_urls)[:events].matches('%"form.completed"%'))
                             .find_by(id: params[:webhook_id])

    if submitter.blank? || webhook.blank?
      return redirect_back(fallback_location: settings_webhooks_path,
                           alert: I18n.t('unable_to_resend_webhook_request'))
    end

    SendFormCompletedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                     'webhook_url_id' => webhook.id)

    redirect_back(fallback_location: settings_webhooks_path, notice: I18n.t('webhook_request_has_been_sent'))
  end

  private

  def load_webhook_url
    @webhook_url = current_account.webhook_urls.find_by(id: params[:id])

    redirect_to settings_webhooks_path unless @webhook_url
  end

  def create_webhook_params
    params.require(:webhook_url).permit(:url, events: []).reverse_merge(events: [])
  end

  def update_webhook_params
    params.require(:webhook_url).permit(:url)
  end
end
