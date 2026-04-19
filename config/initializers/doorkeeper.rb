# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # Runs inside Warden context. Redirect to the Devise sign-in page if the
  # visitor is not logged in, remembering where to return after auth.
  resource_owner_authenticator do
    if current_user
      current_user
    else
      session[:user_return_to] = request.fullpath
      redirect_to(main_app.new_user_session_url)
      nil
    end
  end

  resource_owner_from_credentials { nil } # no Resource Owner Password Credentials grant

  # Doorkeeper's built-in controllers (Authorizations, TokenInfo, AuthorizedApps)
  # inherit from this. Must be an HTML controller so the consent view renders.
  base_controller 'ApplicationController'

  grant_flows %w[authorization_code refresh_token]

  # PKCE: S256 only; required for all non-confidential (public) clients.
  pkce_code_challenge_methods %w[S256]
  force_pkce

  # Require HTTPS for redirect_uri except for loopback (OAuth 2.1 §8.4.2).
  force_ssl_in_redirect_uri do |uri|
    !%w[localhost 127.0.0.1 ::1].include?(uri.host)
  end

  default_scopes  :mcp
  optional_scopes :mcp

  access_token_expires_in 1.hour
  use_refresh_token

  # Hash access-token and refresh-token secrets in the DB.
  hash_token_secrets using: '::Doorkeeper::SecretStoring::Sha256Hash'

  # Always show the consent screen.
  skip_authorization { false }
end

# Doorkeeper's own controllers inherit ApplicationController which enables CanCan
# check_authorization. Exempt them — they have no CanCan subjects.
Rails.application.config.to_prepare do
  %w[
    Doorkeeper::AuthorizationsController
    Doorkeeper::TokensController
    Doorkeeper::TokenInfoController
    Doorkeeper::AuthorizedApplicationsController
  ].each do |name|
    klass = name.safe_constantize
    klass.skip_authorization_check if klass && klass.respond_to?(:skip_authorization_check)
  end
end
