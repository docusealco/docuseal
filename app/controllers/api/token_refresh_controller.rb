# frozen_string_literal: true

module Api
  class TokenRefreshController < ApiBaseController
    skip_before_action :authenticate_via_token!
    skip_authorization_check

    def create
      service = TokenRefreshService.new(token_refresh_params)
      new_token = service.refresh_token

      if new_token
        render json: { access_token: new_token }, status: :ok
      else
        render json: { error: 'Unable to refresh token. User may not exist.' }, status: :unprocessable_entity
      end
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "Token refresh error: #{e.message}"
      render json: { error: 'Internal server error during token refresh' }, status: :internal_server_error
    end

    private

    def token_refresh_params
      params.permit(:account, :partnership, :external_account_id, user: %i[external_id email first_name last_name])
            .to_h.deep_symbolize_keys
    end
  end
end
