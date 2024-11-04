# frozen_string_literal: true

class TestingApiSettingsController < ApplicationController
  def index
    authorize!(:manage, current_user.access_token)

    @webhook_url = current_account.webhook_urls.first_or_initialize

    authorize!(:manage, @webhook_url)
  end
end
