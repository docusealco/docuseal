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

    unless Rails.env.development?
      rescue_from CanCan::AccessDenied do |e|
        render json: { error: access_denied_error_message(e) }, status: :forbidden
      end

      rescue_from JSON::ParserError do |e|
        Rollbar.warning(e) if defined?(Rollbar)

        render json: { error: "JSON parse error: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    def access_denied_error_message(error)
      return 'Not authorized' if request.headers['X-Auth-Token'].blank?
      return 'Not authorized' unless error.subject.is_a?(ActiveRecord::Base)
      return 'Not authorized' unless error.subject.respond_to?(:account_id)

      linked_account_record_exists =
        if current_user.account.testing?
          current_user.account.linked_account_accounts.where(account_type: 'testing')
                      .exists?(account_id: error.subject.account_id)
        else
          current_user.account.testing_accounts.exists?(id: error.subject.account_id)
        end

      return 'Not authorized' unless linked_account_record_exists

      object_name = error.subject.model_name.human
      id = error.subject.id

      if current_user.account.testing?
        "#{object_name} #{id} not found using testing API key; Use production API key to " \
          "access production #{object_name.downcase.pluralize}."
      else
        "#{object_name} #{id} not found using production API key; Use testing API key to " \
          "access testing #{object_name.downcase.pluralize}."
      end
    end

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
