# frozen_string_literal: true

module Api
  class UsersController < ApiBaseController
    authorize_resource :current_user

    def show
      render json: current_user.as_json(only: %i[id first_name last_name email])
    end
  end
end
