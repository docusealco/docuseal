# frozen_string_literal: true

module Api
  class ApiBaseController < ActionController::API
    include ActiveStorage::SetCurrent
    include Pagy::Backend

    DEFAULT_LIMIT = 10
    MAX_LIMIT = 100

    wrap_parameters false

    before_action :authenticate_user!
    check_authorization

    if Rails.env.production?
      rescue_from CanCan::AccessDenied do |e|
        Rollbar.error(e) if defined?(Rollbar)

        render json: { error: e.message }, status: :forbidden
      end
    end

    private

    def paginate(relation)
      result = relation.order(id: :desc)
                       .limit([params.fetch(:limit, DEFAULT_LIMIT).to_i, MAX_LIMIT].min)

      result = result.where('id < ?', params[:after]) if params[:after].present?
      result = result.where('id > ?', params[:before]) if params[:before].present?

      result
    end

    def current_account
      current_user&.account
    end
  end
end
