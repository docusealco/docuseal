# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Storage Settings' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }

  before do
    sign_in(user)
  end

  context 'when storage settings are not set' do
    before do
      visit settings_storage_index_path
    end

    context 'when Disk is selected' do
      it 'shows default storage settings page' do
        expect(page).to have_content('Storage')
        expect(page).to have_content('Store all files on disk')
        expect(page).to have_content('No configs are needed but make sure your disk is persistent')
        expect(page).to have_checked_field('Disk')
      end
    end

    context 'when AWS S3 is selected' do
      it 'setups AWS S3 storage settings' do
        choose 'AWS'

        fill_in 'Access key ID', with: 'access_key_id'
        fill_in 'Secret access key', with: 'secret_access_key'
        fill_in 'Region', with: 'us-west-1'
        fill_in 'Bucket', with: 'bucket'
        fill_in 'Endpoint', with: 'https://s3.us-west-1.amazonaws.com'

        expect do
          click_button 'Save'
        end.to change(EncryptedConfig, :count).by(1)

        encrypted_config = EncryptedConfig.find_by(account:, key: EncryptedConfig::FILES_STORAGE_KEY)
        configs = encrypted_config.value['configs']

        expect(encrypted_config.value['service']).to eq('aws_s3')
        expect(configs['access_key_id']).to eq('access_key_id')
        expect(configs['secret_access_key']).to eq('secret_access_key')
        expect(configs['region']).to eq('us-west-1')
        expect(configs['bucket']).to eq('bucket')
        expect(configs['endpoint']).to eq('https://s3.us-west-1.amazonaws.com')
      end
    end

    context 'when Google Cloud Storage is selected' do
      it 'setups Google Cloud Storage settings' do
        choose 'GCP'

        fill_in 'Project', with: 'project_id'
        fill_in 'Bucket', with: 'bucket'
        fill_in 'Credentials (JSON key content)', with: '{ "type": "service_account", "project_id": "project_id" }'

        expect do
          click_button 'Save'
        end.to change(EncryptedConfig, :count).by(1)

        encrypted_config = EncryptedConfig.find_by(account:, key: EncryptedConfig::FILES_STORAGE_KEY)
        configs = encrypted_config.value['configs']

        expect(encrypted_config.value['service']).to eq('google')
        expect(configs['project']).to eq('project_id')
        expect(configs['bucket']).to eq('bucket')
        expect(configs['credentials']).to eq('{ "type": "service_account", "project_id": "project_id" }')
      end
    end

    context 'when Azure is selected' do
      it 'setup Azure storage settings' do
        choose 'Azure'

        fill_in 'Storage Account Name', with: 'storage_account_name'
        fill_in 'Container', with: 'container'
        fill_in 'Storage Access Key', with: 'storage_access_key'

        expect do
          click_button 'Save'
        end.to change(EncryptedConfig, :count).by(1)

        encrypted_config = EncryptedConfig.find_by(account:, key: EncryptedConfig::FILES_STORAGE_KEY)
        configs = encrypted_config.value['configs']

        expect(encrypted_config.value['service']).to eq('azure')
        expect(configs['storage_account_name']).to eq('storage_account_name')
        expect(configs['container']).to eq('container')
        expect(configs['storage_access_key']).to eq('storage_access_key')
      end
    end
  end

  context 'when storage settings are set' do
    context 'when updates the same storage settings' do
      context 'when AWS S3' do
        let!(:encrypted_config) do
          create(:encrypted_config, account:, key: EncryptedConfig::FILES_STORAGE_KEY, value: {
                   service: 'aws_s3',
                   configs: {
                     access_key_id: 'access_key_id',
                     secret_access_key: 'secret_access_key',
                     region: 'us-west-1',
                     bucket: 'bucket',
                     endpoint: 'https://s3.us-west-1.amazonaws.com'
                   }
                 })
        end

        it 'updates AWS S3 storage settings' do
          visit settings_storage_index_path

          fill_in 'Access key ID', with: 'new_access_key_id'
          fill_in 'Secret access key', with: 'new_secret_access_key'
          fill_in 'Region', with: 'us-west-2'
          fill_in 'Bucket', with: 'new_bucket'
          fill_in 'Endpoint', with: 'https://s3.us-west-2.amazonaws.com'

          expect do
            click_button 'Save'
          end.not_to(change(EncryptedConfig, :count))

          encrypted_config.reload
          configs = encrypted_config.value['configs']

          expect(encrypted_config.value['service']).to eq('aws_s3')
          expect(configs['access_key_id']).to eq('new_access_key_id')
          expect(configs['secret_access_key']).to eq('new_secret_access_key')
          expect(configs['region']).to eq('us-west-2')
          expect(configs['bucket']).to eq('new_bucket')
          expect(configs['endpoint']).to eq('https://s3.us-west-2.amazonaws.com')
        end
      end

      context 'when Google Cloud Storage' do
        let!(:encrypted_config) do
          create(:encrypted_config, account:, key: EncryptedConfig::FILES_STORAGE_KEY, value: {
                   service: 'google',
                   configs: {
                     project: 'project_id',
                     bucket: 'bucket',
                     credentials: '{ "type": "service_account", "project_id": "project_id" }'
                   }
                 })
        end

        it 'updates Google Cloud Storage settings' do
          visit settings_storage_index_path

          fill_in 'Project', with: 'new_project_id'
          fill_in 'Bucket', with: 'new_bucket'
          fill_in 'Credentials (JSON key content)',
                  with: '{ "type": "new_service_account", "project_id": "new_project_id" }'

          expect do
            click_button 'Save'
          end.not_to(change(EncryptedConfig, :count))

          encrypted_config.reload
          configs = encrypted_config.value['configs']

          expect(encrypted_config.value['service']).to eq('google')
          expect(configs['project']).to eq('new_project_id')
          expect(configs['bucket']).to eq('new_bucket')
          expect(configs['credentials']).to eq('{ "type": "new_service_account", "project_id": "new_project_id" }')
        end
      end

      context 'when Azure' do
        let!(:encrypted_config) do
          create(:encrypted_config, account:, key: EncryptedConfig::FILES_STORAGE_KEY, value: {
                   service: 'azure',
                   configs: {
                     storage_account_name: 'storage_account_name',
                     container: 'container',
                     storage_access_key: 'storage_access_key'
                   }
                 })
        end

        it 'updates Azure storage settings' do
          visit settings_storage_index_path

          fill_in 'Storage Account Name', with: 'new_storage_account_name'
          fill_in 'Container', with: 'new_container'
          fill_in 'Storage Access Key', with: 'new_storage_access_key'

          expect do
            click_button 'Save'
          end.not_to(change(EncryptedConfig, :count))

          encrypted_config.reload
          configs = encrypted_config.value['configs']

          expect(encrypted_config.value['service']).to eq('azure')
          expect(configs['storage_account_name']).to eq('new_storage_account_name')
          expect(configs['container']).to eq('new_container')
          expect(configs['storage_access_key']).to eq('new_storage_access_key')
        end
      end
    end

    context 'when switches to another storage settings' do
      context 'when Google Cloud Storage' do
        let!(:encrypted_config) do
          create(:encrypted_config, account:, key: EncryptedConfig::FILES_STORAGE_KEY, value: {
                   service: 'google',
                   configs: {
                     project: 'project_id',
                     bucket: 'bucket',
                     credentials: '{ "type": "service_account", "project_id": "project_id" }'
                   }
                 })
        end

        it 'switches to AWS S3' do
          visit settings_storage_index_path
          choose 'AWS'

          fill_in 'Access key ID', with: 'access_key_id'
          fill_in 'Secret access key', with: 'secret_access_key'
          fill_in 'Region', with: 'us-west-1'
          fill_in 'Bucket', with: 'bucket'
          fill_in 'Endpoint', with: 'https://s3.us-west-1.amazonaws.com'

          expect do
            click_button 'Save'
          end.not_to(change(EncryptedConfig, :count))

          encrypted_config.reload
          configs = encrypted_config.value['configs']

          expect(encrypted_config.value['service']).to eq('aws_s3')
          expect(configs['access_key_id']).to eq('access_key_id')
          expect(configs['secret_access_key']).to eq('secret_access_key')
          expect(configs['region']).to eq('us-west-1')
          expect(configs['bucket']).to eq('bucket')
          expect(configs['endpoint']).to eq('https://s3.us-west-1.amazonaws.com')
        end
      end
    end
  end
end
