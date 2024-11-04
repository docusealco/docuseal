# frozen_string_literal: true

class WebhookPreferencesController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false

  def update
    webhook_preferences_params[:events].each do |event, val|
      @webhook_url.events.delete(event) if val == '0'
      @webhook_url.events.push(event) if val == '1' && @webhook_url.events.exclude?(event)
    end

    @webhook_url.save!

    head :ok
  end

  private

  def webhook_preferences_params
    params.require(:webhook_url).permit(events: {})
  end
end
