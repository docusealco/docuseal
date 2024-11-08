# frozen_string_literal: true

class WebhookSecretController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false

  def show; end

  def update
    @webhook_url.update!(secret: {
      webhook_secret_params[:key] => webhook_secret_params[:value]
    }.compact_blank)

    redirect_back(fallback_location: settings_webhook_path(@webhook_url),
                  notice: I18n.t('webhook_secret_has_been_saved'))
  end

  private

  def webhook_secret_params
    params.require(:webhook_url).permit(secret: %i[key value]).fetch(:secret, {})
  end
end
