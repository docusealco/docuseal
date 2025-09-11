# frozen_string_literal: true

module Api
  class ExternalAuthController < Api::ApiBaseController
    skip_before_action :authenticate_via_token!
    skip_authorization_check

    def user_token
      service = ExternalAuthService.new(params)
      access_token = service.authenticate_user

      render json: { access_token: access_token }
    rescue StandardError => e
      Rails.logger.error("External auth error: #{e.message}")
      Rollbar.error(e) if defined?(Rollbar)
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end
end
