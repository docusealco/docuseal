# frozen_string_literal: true

class TestingApiSettingsController < ApplicationController
  def index
    raise CanCan::AccessDenied unless current_account.testing?

    authorize!(:manage, current_user.access_token)

    @webhook_url = current_account.webhook_urls.first_or_initialize

    authorize!(:manage, @webhook_url)
  end
end
