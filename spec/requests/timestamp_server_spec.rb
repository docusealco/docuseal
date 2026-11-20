# frozen_string_literal: true

RSpec.describe 'Timestamp Server' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let(:timeserver_url) { 'https://tsa.example.com/tsa' }

  before do
    sign_in(user)
  end

  context 'when timeserver responds successfully' do
    before do
      stub_request(:post, timeserver_url).to_return(status: 200, body: 'timestamp-token')
    end

    it 'stores the url and custom headers' do
      post timestamp_server_index_path, params: {
        encrypted_config: { url: timeserver_url, headers: "X-Api-Key: secret\nAuthorization: Bearer token" }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)

      expect(config.value).to eq(
        'url' => timeserver_url,
        'headers' => { 'X-Api-Key' => 'secret', 'Authorization' => 'Bearer token' }
      )
    end

    it 'sends the custom headers when testing the timeserver' do
      post timestamp_server_index_path, params: {
        encrypted_config: { url: timeserver_url, headers: 'X-Api-Key: secret' }
      }

      expect(WebMock).to have_requested(:post, timeserver_url).with(headers: { 'X-Api-Key' => 'secret' })
    end

    it 'skips malformed header lines' do
      post timestamp_server_index_path, params: {
        encrypted_config: { url: timeserver_url, headers: "no-colon-here\nBad Name: value\nX-Ok: yes" }
      }

      config = EncryptedConfig.find_by(account:, key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY)

      expect(config.value['headers']).to eq('X-Ok' => 'yes')
    end
  end

  context 'when timeserver rejects the request' do
    before do
      stub_request(:post, timeserver_url).to_return(status: 500, body: '')
    end

    it 'does not store the configuration' do
      expect do
        post timestamp_server_index_path, params: {
          encrypted_config: { url: timeserver_url, headers: 'X-Api-Key: secret' }
        }
      end.not_to change(EncryptedConfig, :count)
    end
  end

  context 'when url is blank' do
    before do
      create(:encrypted_config, account:, key: EncryptedConfig::TIMESTAMP_SERVER_URL_KEY,
                                value: { 'url' => timeserver_url, 'headers' => { 'X-Api-Key' => 'secret' } })
    end

    it 'removes the configuration' do
      expect do
        post timestamp_server_index_path, params: { encrypted_config: { url: '', headers: '' } }
      end.to change(EncryptedConfig, :count).by(-1)
    end
  end
end
