# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_change, :change

describe 'Internal Provision Account API' do
  let(:secret) { 'test-provision-secret' }

  before { allow(ENV).to receive(:[]).and_call_original }

  def sign_token(payload, sign_with: secret)
    body = Base64.urlsafe_encode64(payload.to_json, padding: false)
    sig = OpenSSL::HMAC.hexdigest('SHA256', sign_with, body)
    "#{body}.#{sig}"
  end

  def valid_payload(overrides = {})
    {
      'est' => SecureRandom.uuid,
      'email' => 'owner@example.com',
      'name' => 'Acme Clinic',
      'exp' => 5.minutes.from_now.to_i
    }.merge(overrides)
  end

  describe 'POST /api/internal/provision_account' do
    context 'with the secret configured' do
      before { allow(ENV).to receive(:[]).with('DOCUSEAL_PROVISION_SECRET').and_return(secret) }

      it 'creates an account, owner, and access token' do
        expect do
          post '/api/internal/provision_account',
               headers: { 'X-Provision-Token': sign_token(valid_payload) }
        end.to change(Account, :count).by(1).and change(User, :count).by(1)

        expect(response).to have_http_status(:ok)

        user = User.find_by(email: 'owner@example.com')
        expect(user.account.name).to eq('Acme Clinic')
        expect(user.account.timezone).to eq('UTC')
        expect(user.account.locale).to eq('en-US')
        expect(user.role).to eq(User::ADMIN_ROLE)

        body = response.parsed_body
        expect(body['email']).to eq('owner@example.com')
        expect(body['access_token']).to eq(user.access_token.token)
        expect(body['account_uuid']).to eq(user.account.uuid)
      end

      it 'is idempotent — repeated calls reuse the same user, account, and token' do
        post '/api/internal/provision_account', headers: { 'X-Provision-Token': sign_token(valid_payload) }
        first = response.parsed_body

        expect do
          post '/api/internal/provision_account', headers: { 'X-Provision-Token': sign_token(valid_payload) }
        end.to not_change(Account, :count).and not_change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['access_token']).to eq(first['access_token'])
        expect(response.parsed_body['account_uuid']).to eq(first['account_uuid'])
      end

      it 'rejects a token signed with the wrong secret' do
        post '/api/internal/provision_account',
             headers: { 'X-Provision-Token': sign_token(valid_payload, sign_with: 'wrong-secret') }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
        expect(User.count).to eq(0)
      end

      it 'rejects an expired token' do
        post '/api/internal/provision_account',
             headers: { 'X-Provision-Token': sign_token(valid_payload('exp' => 5.minutes.ago.to_i)) }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
      end

      it 'rejects a malformed token' do
        post '/api/internal/provision_account', headers: { 'X-Provision-Token': 'not-a-real-token' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects a missing token' do
        post '/api/internal/provision_account'

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
      end
    end

    context 'when the secret is not configured' do
      before { allow(ENV).to receive(:[]).with('DOCUSEAL_PROVISION_SECRET').and_return(nil) }

      it 'fails closed with 401 even for an otherwise-valid token' do
        post '/api/internal/provision_account',
             headers: { 'X-Provision-Token': sign_token(valid_payload) }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq('error' => 'unauthorized')
        expect(User.count).to eq(0)
      end
    end
  end
end
