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

    rescue_from RateLimit::LimitApproached do |e|
      Rollbar.error(e) if defined?(Rollbar)

      render json: { error: 'Too many requests' }, status: :too_many_requests
    end

    if Rails.env.production?
      rescue_from CanCan::AccessDenied do |e|
        render json: { error: e.message }, status: :forbidden
      end

      rescue_from JSON::ParserError do |e|
        Rollbar.warning(e) if defined?(Rollbar)

        render json: { error: "JSON parse error: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    def paginate(relation, field: :id)
      result = relation.order(field => :desc)
                       .limit([params.fetch(:limit, DEFAULT_LIMIT).to_i, MAX_LIMIT].min)

      if field == :id
        result = result.where(id: ...params[:after].to_i) if params[:after].present?
        result = result.where(id: (params[:before].to_i + 1)...) if params[:before].present?
      else
        result = result.where(field => ...params[:after]) if params[:after].present?
        result = result.where(field => (params[:before] + 1)...) if params[:before].present?
      end

      result
    end

    def authenticate_user!
      render json: { error: 'Not authenticated' }, status: :unauthorized unless current_user
    end

    def current_user
      super || @current_user ||=
                 if request.headers['X-Auth-Token'].present?
                   sha256 = Digest::SHA256.hexdigest(request.headers['X-Auth-Token'])

                   User.joins(:access_token).active.find_by(access_token: { sha256: })
                 end
    end

    def current_account
      current_user&.account
    end

    def set_noindex_headers
      headers['X-Robots-Tag'] = 'noindex'
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
