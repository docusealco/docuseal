# frozen_string_literal: true

module OAuth2
  module Strategy
    # The Resource Owner Password Credentials Authorization Strategy
    #
    # IMPORTANT (OAuth 2.1): The Resource Owner Password Credentials grant is omitted in OAuth 2.1.
    # It remains here for backward compatibility with OAuth 2.0 providers. Prefer Authorization Code + PKCE.
    #
    # References:
    # - OAuth 2.1 draft: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-13
    # - Okta explainer: https://developer.okta.com/blog/2019/12/13/oauth-2-1-how-many-rfcs
    # - FusionAuth blog: https://fusionauth.io/blog/2020/04/15/whats-new-in-oauth-2-1
    #
    # @see http://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-15#section-4.3
    class Password < Base
      # Not used for this strategy
      #
      # @raise [NotImplementedError]
      def authorize_url
        raise(NotImplementedError, "The authorization endpoint is not used in this strategy")
      end

      # Retrieve an access token given the specified End User username and password.
      #
      # @param [String] username the End User username
      # @param [String] password the End User password
      # @param [Hash] params additional params
      def get_token(username, password, params = {}, opts = {})
        params = {
          "grant_type" => "password",
          "username" => username,
          "password" => password,
        }.merge(params)
        @client.get_token(params, opts)
      end
    end
  end
end
