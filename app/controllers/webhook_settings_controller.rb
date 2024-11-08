# frozen_string_literal: true

class WebhookSettingsController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false, only: %i[index show new create update destroy]
  load_and_authorize_resource :webhook_url, only: %i[resend], id_param: :webhook_id

  def index
    @webhook_urls = @webhook_urls.order(id: :desc)
    @webhook_url = @webhook_urls.first_or_initialize

    render @webhook_urls.size > 1 ? 'index' : 'show'
  end

  def show; end

  def new; end

  def create
    @webhook_url.save!

    redirect_to settings_webhooks_path, notice: I18n.t('webhook_url_has_been_saved')
  end

  def update
    @webhook_url.update!(update_params)

    redirect_back(fallback_location: settings_webhook_path(@webhook_url),
                  notice: I18n.t('webhook_url_has_been_updated'))
  end

  def destroy
    @webhook_url.destroy!

    redirect_to settings_webhooks_path, notice: I18n.t('webhook_url_has_been_deleted')
  end

  def resend
    submitter = current_account.submitters.where.not(completed_at: nil).order(:id).last

    if submitter.blank? || @webhook_url.blank?
      return redirect_back(fallback_location: settings_webhooks_path,
                           alert: I18n.t('unable_to_resend_webhook_request'))
    end

    SendFormCompletedWebhookRequestJob.perform_async('submitter_id' => submitter.id,
                                                     'webhook_url_id' => @webhook_url.id)

    redirect_back(fallback_location: settings_webhooks_path, notice: I18n.t('webhook_request_has_been_sent'))
  end

  private

  def create_params
    params.require(:webhook_url).permit(:url, events: []).reverse_merge(events: [])
  end

  def update_params
    params.require(:webhook_url).permit(:url)
  end
end
