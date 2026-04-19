# frozen_string_literal: true

module Oauth
  class RegisterController < ActionController::API
    THROTTLE_LIMIT  = 20
    THROTTLE_WINDOW = 1.hour

    rescue_from JSON::ParserError do
      render json: { error: 'invalid_client_metadata' }, status: :bad_request
    end

    def create
      return render_error('rate_limited', :too_many_requests) if throttled?

      body = JSON.parse(request.raw_post.presence || '{}')

      redirect_uris = Array(body['redirect_uris']).map(&:to_s).reject(&:blank?)
      return render_error('invalid_redirect_uri') if redirect_uris.empty?
      return render_error('invalid_redirect_uri') unless redirect_uris.all? { |u| valid_redirect?(u) }

      app = Doorkeeper::Application.create!(
        name: body['client_name'].to_s.presence || "MCP client #{SecureRandom.hex(4)}",
        redirect_uri: redirect_uris.join("\n"),
        scopes: 'mcp',
        confidential: false
      )

      render json: {
        client_id: app.uid,
        client_id_issued_at: app.created_at.to_i,
        client_secret_expires_at: 0,
        redirect_uris: redirect_uris,
        grant_types: %w[authorization_code refresh_token],
        response_types: %w[code],
        token_endpoint_auth_method: 'none',
        scope: 'mcp',
        client_name: app.name
      }, status: :created
    end

    private

    def render_error(code, status = :bad_request)
      render json: { error: code }, status: status
    end

    def valid_redirect?(uri_str)
      uri = URI.parse(uri_str)
      return true if uri.scheme == 'https'
      return true if uri.scheme == 'http' && %w[localhost 127.0.0.1 ::1].include?(uri.host)

      false
    rescue URI::InvalidURIError
      false
    end

    def throttled?
      key = "dcr:#{request.ip}"
      count = Rails.cache.increment(key, 1, expires_in: THROTTLE_WINDOW)
      count && count > THROTTLE_LIMIT
    end
  end
end
