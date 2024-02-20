# frozen_string_literal: true

module Api
  class ApiBaseController < ActionController::API
    include ActiveStorage::SetCurrent
    include Pagy::Backend

    DEFAULT_LIMIT = 10
    MAX_LIMIT = 100

    impersonates :user, with: ->(uuid) { User.find_by(uuid:) }

    wrap_parameters false

    before_action :authenticate_user!
    check_authorization

    rescue_from Params::BaseValidator::InvalidParameterError do |e|
      render json: { error: e.message }, status: :unprocessable_entity
    end

    if Rails.env.production?
      rescue_from CanCan::AccessDenied do |e|
        Rollbar.warning(e) if defined?(Rollbar)

        render json: { error: e.message }, status: :forbidden
      end

      rescue_from JSON::ParserError do |e|
        Rollbar.warning(e) if defined?(Rollbar)

        render json: { error: "JSON parse error: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    def paginate(relation)
      result = relation.order(id: :desc)
                       .limit([params.fetch(:limit, DEFAULT_LIMIT).to_i, MAX_LIMIT].min)

      result = result.where(relation.arel_table[:id].lt(params[:after])) if params[:after].present?
      result = result.where(relation.arel_table[:id].gt(params[:before])) if params[:before].present?

      result
    end

    def authenticate_user!
      @current_user ||=
        if request.headers['X-Auth-Token'].present?
          sha256 = Digest::SHA256.hexdigest(request.headers['X-Auth-Token'])

          User.joins(:access_token).active.find_by(access_token: { sha256: })
        end

      render json: { error: 'Not authenticated' }, status: :unauthorized unless current_user
    end

    def current_account
      current_user&.account
    end

    def set_cors_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, PATCH, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = '*'
      headers['Access-Control-Max-Age'] = '1728000'
      headers['Access-Control-Allow-Credentials'] = true
    end
  end
end
