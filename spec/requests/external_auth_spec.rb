# frozen_string_literal: true

describe 'External Auth API' do
  describe 'POST /api/external_auth/user_token' do
    let(:valid_params) do
      {
        account: {
          external_id: '123',
          name: 'Test Company'
        },
        user: {
          external_id: '456',
          email: 'test@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
      }
    end

    it 'returns success with access token' do
      post '/api/external_auth/user_token', params: valid_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to have_key('access_token')
    end

    it 'returns error when params cause exception' do
      allow(Account).to receive(:find_or_create_by_external_id).and_raise(StandardError.new('Test error'))

      post '/api/external_auth/user_token', params: valid_params, as: :json

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body).to eq({ 'error' => 'Internal server error' })
    end
  end
end
