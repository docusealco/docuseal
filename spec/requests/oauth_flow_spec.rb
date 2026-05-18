# frozen_string_literal: true

require 'rails_helper'
require 'base64'
require 'digest'

RSpec.describe 'Full OAuth 2.1 flow', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:account) { create(:account) }
  let(:user)    { create(:user, account:) }

  before do
    create(:account_config, account:, key: AccountConfig::ENABLE_MCP_KEY, value: true)
  end

  def b64url(bytes) = Base64.urlsafe_encode64(bytes, padding: false)

  it 'register → authorize → token → /mcp round-trips' do
    # 1. Register
    post '/register',
         params: { client_name: 'Test', redirect_uris: ['https://claude.ai/cb'] }.to_json,
         headers: { 'Content-Type' => 'application/json' }
    expect(response).to have_http_status(:created)
    client_id = JSON.parse(response.body).fetch('client_id')

    # 2. PKCE verifier + challenge
    verifier  = b64url(SecureRandom.random_bytes(32))
    challenge = b64url(Digest::SHA256.digest(verifier))

    # 3. Sign in (Devise) and authorize
    sign_in user
    get '/oauth/authorize', params: {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: 'https://claude.ai/cb',
      scope: 'mcp',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    }
    expect(response.status).to satisfy { |s| [200, 302].include?(s) }

    post '/oauth/authorize', params: {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: 'https://claude.ai/cb',
      scope: 'mcp',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    }
    expect(response).to have_http_status(:redirect)
    code = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch('code')

    # 4. Exchange — omitting code_verifier must fail (force_pkce)
    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: 'https://claude.ai/cb',
      client_id: client_id
    }
    expect(response).to have_http_status(:bad_request)

    # 5. Redo: get a fresh code and exchange it with code_verifier.
    post '/oauth/authorize', params: {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: 'https://claude.ai/cb',
      scope: 'mcp',
      code_challenge: challenge,
      code_challenge_method: 'S256'
    }
    code = URI.decode_www_form(URI.parse(response.location).query).to_h.fetch('code')

    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: 'https://claude.ai/cb',
      client_id: client_id,
      code_verifier: verifier
    }
    expect(response).to have_http_status(:ok)
    access_token = JSON.parse(response.body).fetch('access_token')

    # 6. Call /mcp with the access token.
    sign_out user
    post '/mcp',
         params: { jsonrpc: '2.0', method: 'ping', id: 1 }.to_json,
         headers: {
           'Authorization' => "Bearer #{access_token}",
           'Content-Type'  => 'application/json'
         }
    expect(response.status).to satisfy { |s| [200, 202].include?(s) }
  end
end
