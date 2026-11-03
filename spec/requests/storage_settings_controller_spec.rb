# frozen_string_literal: true

RSpec.describe 'StorageSettingsController', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account:) }

  def with_env(overrides)
    previous_values = {}
    overrides.each_key { |key| previous_values[key] = ENV[key] }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  before do
    sign_in(user)
  end

  describe 'POST /settings/storage' do
    it 'does not update storage settings when environment variables manage storage' do
      encrypted_config = create(:encrypted_config, account:, key: EncryptedConfig::FILES_STORAGE_KEY, value: {
                                  service: 'aws_s3',
                                  configs: {
                                    access_key_id: 'db_access_key',
                                    secret_access_key: 'db_secret_key',
                                    region: 'us-east-1',
                                    bucket: 'db-bucket'
                                  }
                                })

      with_env('S3_ATTACHMENTS_BUCKET' => 'env-bucket') do
        expect do
          post settings_storage_index_path, params: {
            encrypted_config: {
              value: {
                service: 'disk',
                configs: {}
              }
            }
          }
        end.not_to(change { encrypted_config.reload.value })

        expect(response).to redirect_to(settings_storage_index_path)
      end
    end
  end
end
