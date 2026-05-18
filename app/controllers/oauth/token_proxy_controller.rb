# frozen_string_literal: true

module Oauth
  # Root-path alias so clients (Claude.ai web) that ignore discovery metadata
  # and POST to /token still hit Doorkeeper's token endpoint.
  class TokenProxyController < Doorkeeper::TokensController
  end
end
