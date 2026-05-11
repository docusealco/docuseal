# frozen_string_literal: true

class WebhookHmacController < ApplicationController
  load_and_authorize_resource :webhook_url, parent: false

  def show; end
end
