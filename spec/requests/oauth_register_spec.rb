# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dynamic Client Registration (RFC 7591)', type: :request do
  let(:valid_body) do
    {
      client_name: 'Claude',
      redirect_uris: ['https://claude.ai/api/mcp/auth_callback']
    }
  end

  def post_register(body)
    post '/register', params: body.to_json,
                      headers: { 'Content-Type' => 'application/json' }
  end

  it 'creates a public Doorkeeper application and returns RFC 7591 fields' do
    expect { post_register(valid_body) }.to change(Doorkeeper::Application, :count).by(1)

    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)

    expect(json['client_id']).to be_present
    expect(json['client_secret_expires_at']).to eq(0)
    expect(json['token_endpoint_auth_method']).to eq('none')
    expect(json['grant_types']).to match_array(%w[authorization_code refresh_token])
    expect(json['response_types']).to eq(['code'])
    expect(json['scope']).to eq('mcp')
    expect(json['redirect_uris']).to eq(['https://claude.ai/api/mcp/auth_callback'])

    app = Doorkeeper::Application.find_by(uid: json['client_id'])
    expect(app).to be_present
    expect(app.confidential).to be(false)
    expect(app.redirect_uri.split("\n")).to eq(['https://claude.ai/api/mcp/auth_callback'])
    expect(app.scopes.to_s).to eq('mcp')
  end

  it 'accepts a loopback http redirect_uri (OAuth 2.1 allowance)' do
    post_register(valid_body.merge(redirect_uris: ['http://127.0.0.1:8765/callback']))
    expect(response).to have_http_status(:created)
  end

  it 'rejects a non-https, non-loopback redirect_uri' do
    post_register(valid_body.merge(redirect_uris: ['http://evil.example.com/cb']))
    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)['error']).to eq('invalid_redirect_uri')
  end

  it 'rejects empty redirect_uris' do
    post_register(valid_body.merge(redirect_uris: []))
    expect(response).to have_http_status(:bad_request)
  end

  it 'rejects malformed JSON' do
    post '/register', params: 'not-json', headers: { 'Content-Type' => 'application/json' }
    expect(response).to have_http_status(:bad_request)
  end

  it 'throttles after 20 requests from the same IP within an hour' do
    20.times { post_register(valid_body) }
    post_register(valid_body)
    expect(response).to have_http_status(:too_many_requests)
  end
end
