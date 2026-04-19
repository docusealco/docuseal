# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MCP endpoint authentication', type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account:) }

  before do
    create(:account_config, account:, key: AccountConfig::ENABLE_MCP_KEY, value: true)
  end

  def post_mcp(token)
    post '/mcp',
         params: { jsonrpc: '2.0', method: 'ping', id: 1 }.to_json,
         headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
  end

  context 'unauthenticated' do
    it 'returns 401 with RFC 9728 WWW-Authenticate header' do
      post '/mcp', params: '{}', headers: { 'Content-Type' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['WWW-Authenticate']).to match(
        %r{\ABearer resource_metadata="http://www\.example\.com/\.well-known/oauth-protected-resource", error="invalid_token"\z}
      )
    end
  end

  context 'with a valid OAuth access token' do
    let(:access_token) do
      create(:oauth_access_token, resource_owner_id: user.id, scopes: 'mcp')
    end

    it 'succeeds and dispatches to HandleRequest' do
      post_mcp(access_token.token)
      expect(response).to have_http_status(:ok).or have_http_status(:accepted)
    end
  end

  context 'with an expired OAuth token' do
    it 'returns 401' do
      token = create(:oauth_access_token, resource_owner_id: user.id, scopes: 'mcp', expires_in: 1)

      travel_to(2.hours.from_now) do
        post_mcp(token.token)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'with a revoked OAuth token' do
    let(:access_token) do
      create(:oauth_access_token, resource_owner_id: user.id, scopes: 'mcp',
                                  revoked_at: 1.minute.ago)
    end

    it 'returns 401' do
      post_mcp(access_token.token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with an OAuth token lacking the mcp scope' do
    let(:access_token) do
      create(:oauth_access_token, resource_owner_id: user.id, scopes: 'other')
    end

    it 'returns 401' do
      post_mcp(access_token.token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with a legacy McpToken bearer (back-compat)' do
    it 'still succeeds' do
      token = build(:mcp_token, user:)
      raw   = token.token
      token.save!

      post_mcp(raw)
      expect(response).to have_http_status(:ok).or have_http_status(:accepted)
    end
  end
end
