# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrefillFieldsHelper, type: :helper do
  # Clear cache before each test to ensure clean state
  before do
    Rails.cache.clear
  end

  describe '#extract_ats_prefill_fields' do
    it 'extracts valid field names from base64 encoded parameter' do
      fields = %w[employee_first_name employee_email manager_firstname]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(fields)
    end

    it 'returns empty array for invalid base64' do
      allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array for invalid JSON' do
      invalid_json = Base64.urlsafe_encode64('invalid json')
      allow(helper).to receive(:params).and_return({ ats_fields: invalid_json })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'filters out invalid field names' do
      fields = %w[employee_first_name malicious_field account_name invalid-field]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(%w[employee_first_name account_name])
    end

    it 'returns empty array when no ats_fields parameter' do
      allow(helper).to receive(:params).and_return({})

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when ats_fields parameter is empty' do
      allow(helper).to receive(:params).and_return({ ats_fields: '' })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when decoded JSON is not an array' do
      not_array = Base64.urlsafe_encode64({ field: 'employee_name' }.to_json)
      allow(helper).to receive(:params).and_return({ ats_fields: not_array })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'returns empty array when array contains non-string values' do
      mixed_array = ['employee_first_name', 123, 'manager_firstname']
      encoded = Base64.urlsafe_encode64(mixed_array.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])
    end

    it 'accepts all valid field name patterns' do
      fields = %w[
        employee_first_name
        employee_middle_name
        employee_last_name
        employee_email
        manager_firstname
        manager_lastname
        account_name
        location_name
        location_street
      ]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })

      result = helper.extract_ats_prefill_fields
      expect(result).to eq(fields)
    end

    it 'logs successful field reception on cache miss' do
      fields = %w[employee_first_name employee_email]
      encoded = Base64.urlsafe_encode64(fields.to_json)

      allow(helper).to receive(:params).and_return({ ats_fields: encoded })
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)

      helper.extract_ats_prefill_fields

      expect(Rails.logger).to have_received(:info).with(
        'Processed and cached 2 ATS prefill fields: employee_first_name, employee_email'
      )
    end

    it 'logs parsing errors and caches empty result' do
      allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:debug)

      result = helper.extract_ats_prefill_fields
      expect(result).to eq([])

      expect(Rails.logger).to have_received(:warn).with(
        a_string_matching(/Failed to parse ATS prefill fields:/)
      )
    end

    # Caching-specific tests
    describe 'caching behavior' do
      let(:fields) { %w[employee_first_name employee_email manager_firstname] }
      let(:encoded) { Base64.urlsafe_encode64(fields.to_json) }

      # Use memory store for caching tests since test environment uses null_store
      around do |example|
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      it 'caches successful parsing results' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)

        # First call should parse and cache
        result1 = helper.extract_ats_prefill_fields
        expect(result1).to eq(fields)

        # Verify cache write occurred
        cache_key = helper.send(:ats_fields_cache_key, encoded)
        cached_value = Rails.cache.read(cache_key)
        expect(cached_value).to eq(fields)
      end

      it 'returns cached results on subsequent calls' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)

        # First call - cache miss
        result1 = helper.extract_ats_prefill_fields
        expect(result1).to eq(fields)

        # Verify cache miss was logged
        expect(Rails.logger).to have_received(:debug).at_least(:once) do |&block|
          block&.call&.include?('cache miss')
        end

        # Reset logger expectations
        allow(Rails.logger).to receive(:debug)

        # Second call - should be cache hit
        result2 = helper.extract_ats_prefill_fields
        expect(result2).to eq(fields)

        # Verify cache hit was logged
        expect(Rails.logger).to have_received(:debug).at_least(:once) do |&block|
          block&.call&.include?('cache hit')
        end
      end

      it 'caches empty results for parsing errors' do
        allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:debug)

        # First call should fail and cache empty result
        result1 = helper.extract_ats_prefill_fields
        expect(result1).to eq([])

        # Verify empty result is cached
        cache_key = helper.send(:ats_fields_cache_key, 'invalid_base64')
        cached_value = Rails.cache.read(cache_key)
        expect(cached_value).to eq([])

        # Reset logger expectations
        allow(Rails.logger).to receive(:debug)

        # Second call should return cached empty result
        result2 = helper.extract_ats_prefill_fields
        expect(result2).to eq([])

        # Verify cache hit was logged
        expect(Rails.logger).to have_received(:debug).at_least(:once) do |&block|
          block&.call&.include?('cache hit')
        end
      end

      it 'generates consistent cache keys for same input' do
        key1 = helper.send(:ats_fields_cache_key, encoded)
        key2 = helper.send(:ats_fields_cache_key, encoded)

        expect(key1).to eq(key2)
        expect(key1).to start_with('ats_fields:')
        expect(key1.length).to be > 20 # Should be a reasonable hash length
      end

      it 'generates different cache keys for different inputs' do
        fields2 = %w[manager_lastname location_name]
        encoded2 = Base64.urlsafe_encode64(fields2.to_json)

        key1 = helper.send(:ats_fields_cache_key, encoded)
        key2 = helper.send(:ats_fields_cache_key, encoded2)

        expect(key1).not_to eq(key2)
      end

      it 'respects cache TTL for successful results' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.cache).to receive(:write).and_call_original

        helper.extract_ats_prefill_fields

        expect(Rails.cache).to have_received(:write).with(
          anything,
          fields,
          expires_in: PrefillFieldsHelper::ATS_FIELDS_CACHE_TTL
        )
      end

      it 'uses shorter TTL for error results' do
        allow(helper).to receive(:params).and_return({ ats_fields: 'invalid_base64' })
        allow(Rails.cache).to receive(:write).and_call_original
        allow(Rails.logger).to receive(:warn)

        helper.extract_ats_prefill_fields

        expect(Rails.cache).to have_received(:write).with(
          anything,
          [],
          expires_in: 5.minutes
        )
      end

      it 'handles cache read failures gracefully' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.cache).to receive(:read).and_raise(StandardError.new('Cache error'))
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:warn)

        # Should fall back to normal processing
        result = helper.extract_ats_prefill_fields
        expect(result).to eq(fields)
        expect(Rails.logger).to have_received(:warn).with('Cache read failed for ATS fields: Cache error')
      end

      it 'handles cache write failures gracefully' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.cache).to receive(:write).and_raise(StandardError.new('Cache error'))
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:warn)

        # Should still return correct result even if caching fails
        result = helper.extract_ats_prefill_fields
        expect(result).to eq(fields)
        expect(Rails.logger).to have_received(:warn).with('Cache write failed for ATS fields: Cache error')
      end
    end

    describe 'performance characteristics' do
      let(:fields) { %w[employee_first_name employee_email manager_firstname] }
      let(:encoded) { Base64.urlsafe_encode64(fields.to_json) }

      # Use memory store for performance tests since test environment uses null_store
      around do |example|
        original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache::MemoryStore.new
        example.run
        Rails.cache = original_cache
      end

      it 'avoids expensive operations on cache hits' do
        allow(helper).to receive(:params).and_return({ ats_fields: encoded })
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:debug)

        # First call to populate cache
        helper.extract_ats_prefill_fields

        # Mock expensive operations to verify they're not called on cache hit
        allow(Base64).to receive(:urlsafe_decode64).and_call_original
        allow(JSON).to receive(:parse).and_call_original

        # Second call should use cache
        result = helper.extract_ats_prefill_fields
        expect(result).to eq(fields)

        # Verify expensive operations were not called on second call
        expect(Base64).not_to have_received(:urlsafe_decode64)
        expect(JSON).not_to have_received(:parse)
      end
    end
  end

  describe '#valid_ats_field_name?' do
    it 'returns true for valid employee field names' do
      expect(helper.send(:valid_ats_field_name?, 'employee_first_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'employee_email')).to be true
      expect(helper.send(:valid_ats_field_name?, 'employee_phone_number')).to be true
    end

    it 'returns true for valid manager field names' do
      expect(helper.send(:valid_ats_field_name?, 'manager_firstname')).to be true
      expect(helper.send(:valid_ats_field_name?, 'manager_lastname')).to be true
      expect(helper.send(:valid_ats_field_name?, 'manager_email')).to be true
    end

    it 'returns true for valid account field names' do
      expect(helper.send(:valid_ats_field_name?, 'account_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'account_id')).to be true
    end

    it 'returns true for valid location field names' do
      expect(helper.send(:valid_ats_field_name?, 'location_name')).to be true
      expect(helper.send(:valid_ats_field_name?, 'location_street')).to be true
      expect(helper.send(:valid_ats_field_name?, 'location_city')).to be true
    end

    it 'returns false for invalid field names' do
      expect(helper.send(:valid_ats_field_name?, 'malicious_field')).to be false
      expect(helper.send(:valid_ats_field_name?, 'invalid-field')).to be false
      expect(helper.send(:valid_ats_field_name?, 'EMPLOYEE_NAME')).to be false
      expect(helper.send(:valid_ats_field_name?, 'employee')).to be false
      expect(helper.send(:valid_ats_field_name?, 'employee_')).to be false
      expect(helper.send(:valid_ats_field_name?, '_employee_name')).to be false
    end
  end
end
