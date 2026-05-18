# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Well-known OAuth metadata', type: :request do
  describe 'GET /.well-known/oauth-authorization-server' do
    it 'returns RFC 8414 metadata with S256 PKCE advertised' do
      get '/.well-known/oauth-authorization-server'

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')

      json = JSON.parse(response.body)
      expect(json['issuer']).to eq('http://www.example.com')
      expect(json['authorization_endpoint']).to eq('http://www.example.com/oauth/authorize')
      expect(json['token_endpoint']).to eq('http://www.example.com/oauth/token')
      expect(json['registration_endpoint']).to eq('http://www.example.com/register')
      expect(json['code_challenge_methods_supported']).to eq(['S256'])
      expect(json['grant_types_supported']).to include('authorization_code', 'refresh_token')
      expect(json['response_types_supported']).to eq(['code'])
      expect(json['token_endpoint_auth_methods_supported']).to eq(['none'])
      expect(json['scopes_supported']).to eq(['mcp'])
    end
  end

  describe 'GET /.well-known/oauth-protected-resource' do
    it 'returns RFC 9728 metadata pointing at /mcp' do
      get '/.well-known/oauth-protected-resource'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['resource']).to eq('http://www.example.com/mcp')
      expect(json['authorization_servers']).to eq(['http://www.example.com'])
      expect(json['scopes_supported']).to eq(['mcp'])
      expect(json['bearer_methods_supported']).to eq(['header'])
    end
  end
end
