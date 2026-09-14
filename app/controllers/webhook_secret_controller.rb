# frozen_string_literal: true

class WebhookSecretController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false

  HEADER_NAME_REGEXP = /\A[\w-]+\z/

  def show; end

  def update
    key = webhook_secret_params[:key]

    if key.present? && !HEADER_NAME_REGEXP.match?(key)
      return redirect_back(fallback_location: settings_webhook_path(@webhook_url), alert: I18n.t('unable_to_save'))
    end

    @webhook_url.update!(secret: {
      key => webhook_secret_params[:value]
    }.compact_blank)

    redirect_back(fallback_location: settings_webhook_path(@webhook_url),
                  notice: I18n.t('webhook_secret_has_been_saved'))
  end

  private

  def webhook_secret_params
    params.require(:webhook_url).permit(secret: %i[key value]).fetch(:secret, {})
  end
end
