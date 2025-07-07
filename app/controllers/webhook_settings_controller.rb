# frozen_string_literal: true

class WebhookSettingsController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false, only: %i[index show new create update destroy]
  load_and_authorize_resource :webhook_url, only: %i[resend], id_param: :webhook_id

  def index
    @webhook_urls = @webhook_urls.order(id: :desc)
    @webhook_url = @webhook_urls.first_or_initialize

    if @webhook_urls.size > 1
      render :index
    else
      @webhook_events = @webhook_url.webhook_events

      @webhook_events = @webhook_events.where(status: params[:status]) if %w[success error].include?(params[:status])

      @pagy, @webhook_events = pagy_countless(@webhook_events.order(id: :desc))

      render :show
    end
  end

  def show
    @webhook_events = @webhook_url.webhook_events

    @webhook_events = @webhook_events.where(status: params[:status]) if %w[success error].include?(params[:status])

    @pagy, @webhook_events = pagy_countless(@webhook_events.order(id: :desc))
  end

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

    authorize!(:read, submitter)

    if submitter.blank? || @webhook_url.blank?
      return redirect_back(fallback_location: settings_webhooks_path,
                           alert: I18n.t('unable_to_resend_webhook_request'))
    end

    SendTestWebhookRequestJob.perform_async(
      'submitter_id' => submitter.id,
      'event_uuid' => SecureRandom.uuid,
      'webhook_url_id' => @webhook_url.id
    )

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
