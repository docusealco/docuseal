# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account, type: :model do
  let(:account) { create(:account) }

  describe '#apply_env_config_overrides' do
    it 'upserts env override values into account_configs' do
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => 'true') do
        account.apply_env_config_overrides
        row = account.account_configs.find_by(key: 'allow_typed_signature')
        expect(row).not_to be_nil
        expect(row.value).to be(true)
      end
    end

    it 'overwrites existing DB value with env value' do
      account.account_configs.create!(key: 'allow_typed_signature', value: false)
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => 'true') do
        account.apply_env_config_overrides
        expect(account.account_configs.find_by(key: 'allow_typed_signature').value).to be(true)
      end
    end
  end

  describe '#config_value' do
    it 'returns env value with locked=true when env set' do
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => 'true') do
        value, locked = account.config_value('allow_typed_signature')
        expect(value).to be(true)
        expect(locked).to be(true)
      end
    end

    it 'returns DB value with locked=false when env absent' do
      account.account_configs.create!(key: 'allow_typed_signature', value: true)
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => nil) do
        value, locked = account.config_value('allow_typed_signature')
        expect(value).to be(true)
        expect(locked).to be(false)
      end
    end

    it 'returns the default when no env var and no DB row' do
      value, locked = account.config_value('nonexistent_key', default: :foo)
      expect(value).to eq(:foo)
      expect(locked).to be(false)
    end
  end

  describe '#ui_visible?' do
    it 'returns false when DB value is false' do
      account.account_configs.create!(key: 'show_console_link', value: false)
      expect(account.ui_visible?('show_console_link')).to be(false)
    end

    it 'returns true when DB value is true' do
      account.account_configs.create!(key: 'show_console_link', value: true)
      expect(account.ui_visible?('show_console_link')).to be(true)
    end

    it 'returns the default when no row and no env var' do
      expect(account.ui_visible?('show_console_link', default: true)).to be(true)
      expect(account.ui_visible?('show_console_link', default: false)).to be(false)
    end
  end
end
