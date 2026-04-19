# frozen_string_literal: true

class WellKnownController < ActionController::API
  def authorization_server
    base = request.base_url
    render json: {
      issuer: base,
      authorization_endpoint: "#{base}/oauth/authorize",
      token_endpoint: "#{base}/oauth/token",
      registration_endpoint: "#{base}/register",
      response_types_supported: %w[code],
      grant_types_supported: %w[authorization_code refresh_token],
      code_challenge_methods_supported: %w[S256],
      token_endpoint_auth_methods_supported: %w[none],
      scopes_supported: %w[mcp]
    }
  end

  def protected_resource
    base = request.base_url
    render json: {
      resource: "#{base}/mcp",
      authorization_servers: [base],
      scopes_supported: %w[mcp],
      bearer_methods_supported: %w[header]
    }
  end
end
