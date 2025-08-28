# frozen_string_literal: true

describe IframeAuthentication do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:token) { user.access_token.token }

  let(:controller_class) do
    Class.new(ApplicationController) do
      include IframeAuthentication
    end
  end

  let(:controller) { controller_class.new }
  let(:request_double) { instance_double(ActionDispatch::Request, headers: {}, referer: nil) }

  before do
    allow(controller).to receive_messages(
      request: request_double,
      params: {},
      session: {},
      signed_in?: false,
      sign_in: nil,
      render: nil
    )
    allow(Rails.logger).to receive(:error)
  end

  describe '#authenticate_from_referer' do
    it 'does nothing when already signed in' do
      allow(controller).to receive(:signed_in?).and_return(true)
      controller.send(:authenticate_from_referer)
      expect(controller).not_to have_received(:sign_in)
    end

    it 'authenticates with valid params token' do
      allow(controller).to receive(:params).and_return({ auth_token: token })
      controller.send(:authenticate_from_referer)
      expect(controller).to have_received(:sign_in).with(user)
    end

    it 'authenticates with valid session token' do
      allow(controller).to receive(:session).and_return({ auth_token: token })
      controller.send(:authenticate_from_referer)
      expect(controller).to have_received(:sign_in).with(user)
    end

    it 'authenticates with valid header token' do
      allow(request_double).to receive(:headers).and_return({ 'X-Auth-Token' => token })
      controller.send(:authenticate_from_referer)
      expect(controller).to have_received(:sign_in).with(user)
    end

    it 'authenticates with token from referer URL' do
      allow(request_double).to receive(:referer).and_return("https://example.com?auth_token=#{token}")
      controller.send(:authenticate_from_referer)
      expect(controller).to have_received(:sign_in).with(user)
    end

    it 'does nothing with invalid token' do
      allow(controller).to receive(:params).and_return({ auth_token: 'invalid' })
      controller.send(:authenticate_from_referer)
      expect(controller).not_to have_received(:sign_in)
      expect(controller).not_to have_received(:render)
    end

    it 'renders error with no token' do
      controller.send(:authenticate_from_referer)
      expect(controller).to have_received(:render).with(
        json: { error: 'Authentication required' },
        status: :unauthorized
      )
    end
  end
end
