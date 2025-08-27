# frozen_string_literal: true

describe 'ApplicationController' do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:token) { user.access_token.token }

  describe 'token authentication methods' do
    let(:controller) { ApplicationController.new }

    let(:request_double) { instance_double(ActionDispatch::Request, headers: {}) }

    before do
      allow(controller).to receive_messages(
        request: request_double,
        params: {},
        session: {},
        signed_in?: false
      )
    end

    describe '#maybe_authenticate_via_token' do
      it 'signs in user with valid token in header' do
        request_double_with_token = instance_double(ActionDispatch::Request, headers: { 'X-Auth-Token' => token })
        allow(controller).to receive(:request).and_return(request_double_with_token)
        allow(controller).to receive(:sign_in)

        controller.send(:maybe_authenticate_via_token)

        expect(controller).to have_received(:sign_in).with(user)
      end

      it 'does nothing with invalid token' do
        request_double_with_invalid = instance_double(ActionDispatch::Request, headers: { 'X-Auth-Token' => 'invalid' })
        allow(controller).to receive(:request).and_return(request_double_with_invalid)
        allow(controller).to receive(:sign_in)

        controller.send(:maybe_authenticate_via_token)

        expect(controller).not_to have_received(:sign_in)
      end
    end

    describe '#authenticate_via_token!' do
      it 'renders error with no token' do
        allow(controller).to receive(:render)

        controller.send(:authenticate_via_token!)

        expect(controller).to have_received(:render).with(
          json: { error: 'Authentication required. Please provide a valid auth_token.' },
          status: :unauthorized
        )
      end

      it 'renders error with invalid token' do
        request_double_with_invalid = instance_double(ActionDispatch::Request, headers: { 'X-Auth-Token' => 'invalid' })
        allow(controller).to receive(:request).and_return(request_double_with_invalid)
        allow(controller).to receive(:render)

        controller.send(:authenticate_via_token!)

        expect(controller).to have_received(:render).with(
          json: { error: 'Authentication required. Please provide a valid auth_token.' },
          status: :unauthorized
        )
      end

      it 'does not render error with valid token' do
        request_double_with_token = instance_double(ActionDispatch::Request, headers: { 'X-Auth-Token' => token })
        allow(controller).to receive(:request).and_return(request_double_with_token)
        allow(controller).to receive_messages(sign_in: nil, render: nil)

        controller.send(:authenticate_via_token!)

        expect(controller).not_to have_received(:render)
        expect(controller).to have_received(:sign_in).with(user)
      end
    end
  end

  describe 'API authentication' do
    context 'with valid token' do
      it 'authenticates user' do
        get '/api/submissions', headers: { 'X-Auth-Token': token }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid token' do
      it 'returns API-specific error message' do
        get '/api/submissions', headers: { 'X-Auth-Token': 'invalid_token' }
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to eq({ 'error' => 'Not authenticated' })
      end
    end
  end
end
