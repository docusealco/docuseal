# frozen_string_literal: true

module Api
  class ApiBaseController < ActionController::API
    include ActiveStorage::SetCurrent

    before_action :authenticate_user!
    check_authorization

    if Rails.env.production?
      rescue_from CanCan::AccessDenied do |e|
        Rollbar.error(e) if defined?(Rollbar)

        render json: { error: e.message }, status: :forbidden
      end
    end

    private

    def current_account
      current_user&.account
    end
  end
end
