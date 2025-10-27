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

    context 'when partnership authentication is used' do
      let(:partnership_params) do
        {
          partnership: { external_id: 'partnership-123', name: 'Test Partnership' },
          user: { external_id: '456', email: 'test@example.com', first_name: 'John', last_name: 'Doe' }
        }
      end

      it 'creates user without account for pure partnership auth' do
        post '/api/external_auth/user_token', params: partnership_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('access_token')

        user = User.find_by(external_user_id: 456)
        expect(user.account_id).to be_nil
      end

      it 'creates user with account for hybrid partnership+account auth' do
        account = create(:account, external_account_id: 789)
        hybrid_params = partnership_params.merge(external_account_id: 789)

        post '/api/external_auth/user_token', params: hybrid_params, as: :json

        expect(response).to have_http_status(:ok)

        user = User.find_by(external_user_id: 456)
        expect(user.account_id).to eq(account.id)
      end

      it 'returns error when account not found' do
        hybrid_params = partnership_params.merge(external_account_id: 999)

        post '/api/external_auth/user_token', params: hybrid_params, as: :json

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
