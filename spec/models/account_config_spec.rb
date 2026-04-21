# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountConfig, type: :model do
  describe '.env_key_for' do
    it 'builds the DOCUSEAL_CONFIG_<UPCASE_KEY> env variable name' do
      expect(described_class.env_key_for('allow_typed_signature'))
        .to eq('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE')
    end
  end

  describe '.locked_by_env?' do
    it 'returns true when the matching env var is set' do
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => 'true') do
        expect(described_class.locked_by_env?('allow_typed_signature')).to be(true)
      end
    end

    it 'returns false when the matching env var is absent' do
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => nil) do
        expect(described_class.locked_by_env?('allow_typed_signature')).to be(false)
      end
    end

    it 'returns false when the matching env var is blank' do
      with_env('DOCUSEAL_CONFIG_ALLOW_TYPED_SIGNATURE' => '') do
        expect(described_class.locked_by_env?('allow_typed_signature')).to be(false)
      end
    end
  end

  describe '.env_override_cast' do
    it 'casts boolean-ish strings to booleans' do
      with_env('DOCUSEAL_CONFIG_FORCE_MFA' => 'true') do
        expect(described_class.env_override_cast('force_mfa')).to be(true)
      end
      with_env('DOCUSEAL_CONFIG_FORCE_MFA' => 'false') do
        expect(described_class.env_override_cast('force_mfa')).to be(false)
      end
      with_env('DOCUSEAL_CONFIG_FORCE_MFA' => '1') do
        expect(described_class.env_override_cast('force_mfa')).to be(true)
      end
      with_env('DOCUSEAL_CONFIG_FORCE_MFA' => '0') do
        expect(described_class.env_override_cast('force_mfa')).to be(false)
      end
    end

    it 'parses valid JSON' do
      with_env('DOCUSEAL_CONFIG_POLICY_LINKS' => '{"a":1}') do
        expect(described_class.env_override_cast('policy_links')).to eq({ 'a' => 1 })
      end
    end

    it 'returns the raw string when not boolean or JSON' do
      with_env('DOCUSEAL_CONFIG_DOCUMENT_FILENAME_FORMAT' => 'hello') do
        expect(described_class.env_override_cast('document_filename_format')).to eq('hello')
      end
    end

    it 'returns nil when the env var is absent' do
      with_env('DOCUSEAL_CONFIG_FORCE_MFA' => nil) do
        expect(described_class.env_override_cast('force_mfa')).to be_nil
      end
    end
  end
end
