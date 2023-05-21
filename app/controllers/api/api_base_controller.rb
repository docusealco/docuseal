# frozen_string_literal: true

module Api
  class ApiBaseController < ActionController::API
    include ActiveStorage::SetCurrent

    before_action :authenticate_user!

    private

    def current_account
      current_user&.account
    end
  end
end
